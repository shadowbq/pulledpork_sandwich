#!/usr/bin/env ruby
require 'rubygems'
require 'fileutils'
require 'shellex'
require 'zlib'
require 'archive/tar/minitar'

require 'json'
require 'yaml'

require 'net/scp'

require 'pry' if debug
include Archive::Tar

class SensorCollection < Array

  def build( data )
    self + data.collect { |sensor| 
      @sensor = Sensor.new
      @sensor.name = sensor[0]
      @sensor.hostname = sensor[1]["hostname"]
      @sensor.ipaddress = sensor[1]["ipaddress"]
      @sensor.notes = sensor[1]["notes"]
      @sensor
    }
  end

require 'singleton'

class SandwichConf

  include Singleton
 
  attr_reader :config

  def initialize(config_file)
    @config = YAML.load_file(config_file)
    RuntimeError.new("Missing defined sensors)")  unless @config['SENSORS'].nil?

    @config['SENSORS'].each_key do |host|
      @config['SENSORS'][host]['notes'] ||= ""
      @config['SENSORS'][host]['tags'] ||= []
      RuntimeError.new("Missing hostname: (#{host})")  unless @config['SENSORS'][host].include? "hostname" 
      RuntimeError.new("Missing ipaddress: (#{host})")  unless @config['SENSORS'][host].include? "ipaddress" 
    end

    #check to see if this host has a hypervisor 
    RuntimeError.new("Missing oinkmaster code")  unless @config['CONFIG'].include? "oinkcode" 
    @config['CONFIG']['debug'] ||= false
    @config['CONFIG']['verbose'] ||= false
    @config['CONFIG']['openvpnlog'] ||= false

    @config
  end
 
end

class Sensor
  attr_accessor :name, :ipaddress, :notes, :hostname
  
  def openvpn
    line = File.readlines(SandwichConf.instance.config['Config']['openvpn_log']).select { |line| line =~ /#{hostname}/ }
    #raise "OpenVPN log search failure" unless line.first
    line[1].split(',').first
  end
  
end

class PulledConf

  def initialize( sensor="example-snort" )
    @sensor = sensor
  end

  def print
    configfile = File.open("#{BASEDIR}/etc/sensors/#{@sensor}/pulledpork.dyn.conf", 'w')
    configfile.puts "#Stat"
    configfile.puts "distro=FreeBSD-8.1"
    configfile.puts "snort_version=2.9.2.3"
    configfile.puts "version=0.6.0"
    configfile.puts "ignore=deleted.rules,experimental.rules"
    configfile.puts ""
    configfile.puts "rule_url=https://www.snort.org/reg-rules/|snortrules-snapshot.tar.gz|23e665c6efc7e4a67601e9c0d11a39207daf16ac"
    configfile.puts "temp_path=/tmp"
    configfile.puts ""
    configfile.puts "#Imports"
    configfile.puts "snort_path=/usr/local/bin/snort"
    configfile.puts "config_path=#{BASEDIR}/etc/snort.conf"
    configfile.puts ""
    configfile.puts "#Modifiers"
    configfile.puts "local_rules=#{BASEDIR}/etc/sensors/#{@sensor}/combined.localrules.conf"
    configfile.puts "enablesid=#{BASEDIR}/etc/sensors/#{@sensor}/combined.enablesid.conf"
    configfile.puts "dropsid=#{BASEDIR}/etc/sensors/#{@sensor}/combined.dropsid.conf"
    configfile.puts "disablesid=#{BASEDIR}/etc/sensors/#{@sensor}/combined.disablesid.conf"
    configfile.puts "modifysid=#{BASEDIR}/etc/sensors/#{@sensor}/combined.modifysid.conf"
    configfile.puts ""
    configfile.puts "#Exports"
    configfile.puts "rule_path=#{BASEDIR}/export/sensors/#{@sensor}/snort.rule"
    configfile.puts "sid_msg=#{BASEDIR}/export/sensors/#{@sensor}/sid-msg.map"
    configfile.puts "sostub_path=#{BASEDIR}/export/sensors/#{@sensor}/so_rules.rules"
    configfile.puts "sorule_path=#{BASEDIR}/export/sensors/#{@sensor}/so_rules/"
    configfile.puts "sid_changelog=#{BASEDIR}/log/#{@sensor}_sid_changes.log"
    configfile.puts ""
    configfile.puts "#Backups (Copy the export to backups dir)"
    configfile.puts "backup=#{BASEDIR}/export/sensors/#{@sensor}/"
    configfile.puts "backup_file=#{BASEDIR}/archive/#{@sensor}_backup"
    configfile.close

  end

end

BASEDIR = '/opt/pulledpork_sandwich'
config_file = "#{BASEDIR}/etc/sandwich.conf"

SandwichConf.instance.new(config_file)

@collection = SensorCollection.new
@collection = @collection.build(SandwichConf.instance.config['SENSORS']) 

@collection.each { |sensor| 
  print "Sensor - #{sensor.name} :" if verbose 

  #Create Directory if not already exists
  print "d" if verbose 
  FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{sensor.name}")
  FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{sensor.name}/so_rules/")
  FileUtils.touch("#{BASEDIR}/export/sensors/#{sensor.name}/so_rules.rules")
  print "." if verbose 

  #Merge Global Policy with Sensor Policy
  print "m" if verbose 
  modifiers = ['localrules','enablesid','dropsid', 'disablesid', 'modifysid']
  global_modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/global.#{modifier}.conf"] }]  
  modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/sensors/#{sensor.name}/#{modifier}.conf"] }]
  
  binding.pry if debug
  global_modifier_filelist.zip(modifier_filelist) do |globalmod,sensormod|
    File.open("#{BASEDIR}/etc/sensors/#{sensor.name}/combined.#{globalmod[0]}.conf",'w') do |output_file|
      output_file.puts File.readlines(globalmod[1]) 
      output_file.puts File.readlines(sensormod[1])   
    end
  end
  print "." if verbose 
  
  #Dynamic Print PulledPork Policy
  print "p"
  pork=PulledConf.new(sensor.name)
  pork.print
  print "." if verbose 

  #Run Pulled Pork for each Sensor
  print "r" if verbose 
  stdout, stderr = shellex("pulledpork.pl -c #{BASEDIR}/etc/sensors/#{sensor.name}/pulledpork.dyn.conf")
  binding.pry if debug
  print "." if verbose 

  #TAR.GZ results 
  print "z" if verbose 
  tgz = Zlib::GzipWriter.new(File.open("#{BASEDIR}/tmp/#{sensor.name}_sig_package.tgz", 'wb'))
  @filelist = Dir["#{BASEDIR}/etc/sensors/#{sensor.name}/export/*.rules", "#{BASEDIR}/etc/sensors/#{sensor.name}/export/*.map"] 
  Minitar.pack(@filelist, tgz) 
  puts "." if verbose 

  #SCP to corresponding sensor
  #puts "SCPing to #{sensor.hostname} - #{sensor.openvpn}"
  #Net::SCP.upload!("remote.host.com", "username", "/local/path", "/remote/path", :ssh => { :password => "password" })

}


