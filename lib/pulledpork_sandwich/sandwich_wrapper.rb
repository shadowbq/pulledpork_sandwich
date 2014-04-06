module Pulledpork_Sandwich
  
  class SandwichWrapper

    def initialize(sensor, oinkcode)
      @sensor = sensor
      @oinkcode = oinkcode
    end

    def combine_modifiers
      modifiers = ['localrules','enablesid','dropsid', 'disablesid', 'modifysid','threshold']

      global_modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/global.#{modifier}.conf"] }]  
      modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/sensors/#{@sensor}/#{modifier}.conf"] }]
      
      global_modifier_filelist.zip(modifier_filelist) do |globalmod,sensormod|
        File.open("#{BASEDIR}/etc/sensors/#{@sensor}/combined.#{globalmod[0]}.conf",'w') do |output_file|
          output_file.puts File.readlines(globalmod[1]) 
          output_file.puts File.readlines(sensormod[1])   
        end
      end
    end  

    def create_config
      configfile = File.open("#{BASEDIR}/etc/sensors/#{@sensor}/pulledpork.dyn.conf", 'w')
      configfile.puts "#Stat"
      configfile.puts "distro=FreeBSD-8.1"
      configfile.puts "snort_version=2.9.2.3"
      configfile.puts "version=0.7.0"
      configfile.puts "ignore=deleted.rules,experimental.rules"
      configfile.puts "sid_msg_version=1"
      configfile.puts ""
      configfile.puts "rule_url=https://www.snort.org/reg-rules/|snortrules-snapshot.tar.gz|#{@oinkcode}"
      configfile.puts "rule_url=https://www.snort.org/reg-rules/|opensource.gz|#{@oinkcode}"      
      configfile.puts "rule_url=https://s3.amazonaws.com/snort-org/www/rules/community/|community-rules.tar.gz|Community"
      configfile.puts "rule_url=http://labs.snort.org/feeds/ip-filter.blf|IPBLACKLIST|open"

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
      configfile.puts "sorule_path=#{BASEDIR}/export/sensors/#{@sensor}/so_rules/"
      configfile.puts "sid_changelog=#{BASEDIR}/log/#{@sensor}_sid_changes.log"
      configfile.puts ""
      configfile.puts "#ClearText"
      configfile.puts "black_list=#{BASEDIR}/etc/default.blacklist"
      configfile.puts "#Path to output IPRVersion.dat"
      configfile.puts "IPRVersion=#{BASEDIR}/export/sensors/#{@sensor}/iplists"
      configfile.puts "# Short circuit call to control bin"
      configfile.puts "snort_control=true"
      configfile.puts ""
      configfile.puts "#Backups (Copy the export to backups dir)"
      configfile.puts "backup=#{BASEDIR}/export/sensors/#{@sensor}/"
      configfile.puts "backup_file=#{BASEDIR}/archive/#{@sensor}_backup"
      configfile.close

    end

    def trigger
      stdout, stderr = shellex("pulledpork.pl -c #{BASEDIR}/etc/sensors/#{@sensor}/pulledpork.dyn.conf")
    end

    def package
      tgz = Zlib::GzipWriter.new(File.open("#{BASEDIR}/tmp/#{@sensor}_sig_package.tgz", 'wb'))
      @filelist = Dir["#{BASEDIR}/etc/sensors/#{@sensor}/export/*.rules", "#{BASEDIR}/etc/sensors/#{@sensor}/export/*.map"] 
      Minitar.pack(@filelist, tgz) 
    end

  end

end