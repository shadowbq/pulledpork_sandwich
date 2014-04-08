module Pulledpork_Sandwich
  
  class SandwichWrapper

    def initialize(sensor, oinkcode, pulledpork)
      @sensor = sensor
      @oinkcode = oinkcode
      @pulledpork = pulledpork
    end

    def combine_modifiers
      modifiers = ['localrules','enablesid','dropsid', 'disablesid', 'modifysid','threshold']

      global_modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/global.#{modifier}.conf"] }]  
      modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/sensors/#{@sensor.name}/#{modifier}.conf"] }]
      
      global_modifier_filelist.zip(modifier_filelist) do |globalmod,sensormod|
        File.open("#{BASEDIR}/etc/sensors/#{@sensor.name}/combined.#{globalmod[0]}.conf",'w') do |output_file|
          output_file.puts File.readlines(globalmod[1]) 
          output_file.puts File.readlines(sensormod[1])   
        end
      end
    end  

    def create_config
      configfile = File.open("#{BASEDIR}/etc/sensors/#{@sensor.name}/pulledpork.dyn.conf", 'w')
      configfile.puts "#Stat"
      configfile.puts "distro=FreeBSD-8.1"
      configfile.puts "snort_version=2.9.2.3"
      configfile.puts "version=0.7.0"
      configfile.puts "ignore=deleted.rules,experimental.rules"
      configfile.puts "sid_msg_version=1"
      configfile.puts ""
      @pulledpork['rules-urls'].each do |k,v|
        if v['oinkcode'] 
          configfile.puts "rule_url=#{v['url']}|#{@oinkcode}"
        else
          configfile.puts "rule_url=#{v['url']}"
        end  
      end
      configfile.puts "rule_url=http://labs.snort.org/feeds/ip-filter.blf|IPBLACKLIST|open"
      configfile.puts "temp_path=#{BASEDIR}/tmp"
      configfile.puts ""
      configfile.puts "# Imports"
      configfile.puts "snort_path=/usr/local/bin/snort"
      configfile.puts "config_path=#{BASEDIR}/etc/snort.conf"
      configfile.puts ""
      configfile.puts "# Modifiers"
      configfile.puts "local_rules=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined.localrules.conf"
      configfile.puts "enablesid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined.enablesid.conf"
      configfile.puts "dropsid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined.dropsid.conf"
      configfile.puts "disablesid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined.disablesid.conf"
      configfile.puts "modifysid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined.modifysid.conf"
      configfile.puts ""
      configfile.puts "# Exports"
      configfile.puts "rule_path=#{BASEDIR}/export/sensors/#{@sensor.name}/snort.rule"
      configfile.puts "sid_msg=#{BASEDIR}/export/sensors/#{@sensor.name}/sid-msg.map"
      configfile.puts "#sorule_path=#{BASEDIR}/export/sensors/#{@sensor.name}/so_rules/"
      configfile.puts "sid_changelog=#{BASEDIR}/log/#{@sensor.name}_sid_changes.log"
      configfile.puts ""
      configfile.puts "# ClearText"
      configfile.puts "black_list=#{BASEDIR}/etc/default.blacklist"
      configfile.puts ""
      configfile.puts "# Path to output IPRVersion.dat"
      configfile.puts "IPRVersion=#{BASEDIR}/export/sensors/#{@sensor.name}/iplists"
      configfile.puts ""
      configfile.puts "# Short circuit call to control bin"
      configfile.puts "snort_control=true"
      configfile.puts ""
      configfile.puts "# Backups (Copy the export to backups dir)"
      configfile.puts "backup=#{BASEDIR}/export/sensors/#{@sensor.name}/"
      configfile.puts "backup_file=#{BASEDIR}/archive/#{@sensor.name}_backup"
      configfile.puts ""
      if sensor.ips_policy 
        configfile.puts "# RuleSet (security, balanced, connectivity)"
        configfile.puts "ips_policy=#{@sensor.policy}"
        configfile.puts ""
      end  
      configfile.close

    end

    def trigger
      # Verbose output 
      # Process even if no new downloads
      # Process text based rules files only, i.e. DO NOT process so_rules
      # use explicit config file
      stdout, stderr = shellex("pulledpork.pl -v -P -T -c #{BASEDIR}/etc/sensors/#{@sensor.name}/pulledpork.dyn.conf")
      File.open("#{BASEDIR}/log/#{@sensor.name}_pulledpork.#{Time.now.to_i}.log", 'w') do |exelog|
        exelog.puts stdout
      end
      File.open("#{BASEDIR}/log/#{@sensor.name}_pulledpork.#{Time.now.to_i}.err", 'w') do |exelog|
        exelog.puts stderr
      end
     
    end

    def package
      tgz = Zlib::GzipWriter.new(File.open("#{BASEDIR}/tmp/#{@sensor.name}_sig_package.tgz", 'wb'))
      @filelist = Dir["#{BASEDIR}/etc/sensors/#{@sensor.name}/export/*.rules", "#{BASEDIR}/etc/sensors/#{@sensor.name}/export/*.map"] 
      Minitar.pack(@filelist, tgz) 
    end

  end

end