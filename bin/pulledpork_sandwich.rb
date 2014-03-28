#!/usr/bin/env ruby

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup(:default)
rescue ::Exception => e
end

# Executable with absolute path to lib for hacking and development
require File.join(File.dirname(__FILE__), '..', 'lib', 'pulledpork_sandwich', 'cli')

Pulledpork_Sandwich::CLI.invoke





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


