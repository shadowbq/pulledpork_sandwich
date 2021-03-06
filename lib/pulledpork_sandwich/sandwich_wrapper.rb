module Pulledpork_Sandwich
  
  # This class wraps the execution of pulledpork.pl per sensor,
  # the creation of each of the pulledpork.conf files, and
  # the packaging of the results into a tar-gz ball.
  class SandwichWrapper

    def initialize(sensor, oinkcode, pulledpork, pulledpork_path)
      @sensor = sensor
      @oinkcode = oinkcode
      @pulledpork = pulledpork
      @pulledpork_path = pulledpork_path
      @time_at = Time.now.to_i
    end

    def combine_modifiers
      modifiers = ['localrules','enablesid','dropsid', 'disablesid', 'modifysid','threshold', 'whitelist']

      global_modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/global.#{modifier}.conf"] }]  
      sensor_modifier_filelist = Hash[modifiers.collect {|modifier| [modifier, "#{BASEDIR}/etc/sensors/#{@sensor.name}/#{modifier}.conf"] }]
      
      global_modifier_filelist.zip(sensor_modifier_filelist) do |globalmod,sensormod|      
        tmpfile = Tempfile.new('config.', "#{BASEDIR}/tmp")
        begin
          configuration = (File.readlines(globalmod[1]) + File.readlines(sensormod[1])).uniq.sort.delete_if {|line| line =~ /^#.*/}
          tmpfile.puts configuration
        ensure
           tmpfile.close
           FileUtils.mkdir_p("#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/")
           FileUtils.cp(tmpfile.path, "#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/#{globalmod[0]}.conf")
           FileUtils.chmod(0644, "#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/#{globalmod[0]}.conf")
           tmpfile.unlink   # deletes the temp file
        end
      end

    end  

    def create_config
      configfile = File.open("#{BASEDIR}/etc/sensors/#{@sensor.name}/pulledpork.dyn.conf", 'w')
      configfile.puts "#Stat"
      configfile.puts "distro=#{@sensor.distro}"
      configfile.puts "snort_version=#{@sensor.snort_version}"
      configfile.puts "version=#{@pulledpork['version']}"
      configfile.puts "ignore=deleted.rules,experimental.rules"
      configfile.puts "sid_msg_version=1"
      configfile.puts ""
      @pulledpork['rules-urls'].each do |k,v|
        if v['explicit'] == true
          configfile.puts "rule_url=#{v['url']}"
        elsif v['oinkcode'] 
          configfile.puts "rule_url=#{v['url']}|#{@oinkcode}"
        end  
      end
      @pulledpork['ip-blacklists'].each do |url|
        configfile.puts "rule_url=#{url}|IPBLACKLIST|open"
      end
      configfile.puts "temp_path=#{BASEDIR}/tmp"
      configfile.puts ""
      configfile.puts "# Imports"
      configfile.puts "snort_path=/usr/local/bin/snort"
      configfile.puts "config_path=#{BASEDIR}/etc/snort.conf"
      configfile.puts ""
      configfile.puts "# Modifiers"
      configfile.puts "local_rules=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/localrules.conf"
      configfile.puts "enablesid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/enablesid.conf"
      configfile.puts "dropsid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/dropsid.conf"
      configfile.puts "disablesid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/disablesid.conf"
      configfile.puts "modifysid=#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/modifysid.conf"
      configfile.puts ""
      configfile.puts "# Exports"
      configfile.puts "rule_path=#{BASEDIR}/export/sensors/#{@sensor.name}/snort.rules"
      configfile.puts "sid_msg=#{BASEDIR}/export/sensors/#{@sensor.name}/sid-msg.map"
      configfile.puts "# sorule_path=#{BASEDIR}/export/sensors/#{@sensor.name}/so_rules/"
      configfile.puts "sid_changelog=#{BASEDIR}/log/#{@sensor.name}_sid_changes.#{@time_at}.log"
      configfile.puts ""
      configfile.puts "# ClearText Combined IP Blacklist"
      configfile.puts "black_list=#{BASEDIR}/export/sensors/#{@sensor.name}/combined.blacklist"
      configfile.puts ""
      configfile.puts "# Path to output IPRVersion.dat"
      configfile.puts "IPRVersion=#{BASEDIR}/export/sensors/#{@sensor.name}/combined."
      configfile.puts ""
      configfile.puts "# Short circuit call to control bin"
      configfile.puts "snort_control=true"
      configfile.puts ""
      if @sensor.ips_policy 
        configfile.puts "# RuleSet (security, balanced, connectivity)"
        configfile.puts "ips_policy=#{@sensor.policy}"
        configfile.puts ""
      end  
      configfile.close

    end

    def trigger(skipdownload='')
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{@sensor.name}")
      
      #Export files not processed by pulledpork
      ['threshold','whitelist'].each do |passthrough|
        FileUtils.cp("#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/#{passthrough}.conf", "#{BASEDIR}/export/sensors/#{@sensor.name}/#{passthrough}.conf")
      end 
      
      # Pulled pork Exection notes: 
      # -v Verbose output 
      # -P Process even if no new downloads
      # -T Process text based rules files only, i.e. DO NOT process so_rules
      # -c use explicit config file
      stdout, stderr = shellex("#{@pulledpork_path} -v -P -T -c #{BASEDIR}/etc/sensors/#{@sensor.name}/pulledpork.dyn.conf #{skipdownload}")

      File.open("#{BASEDIR}/log/#{@sensor.name}_pulledpork.#{@time_at}.log", 'w') do |exelog|
        exelog.puts stdout
      end
      File.open("#{BASEDIR}/log/#{@sensor.name}_pulledpork.#{@time_at}.err", 'w') do |exelog|
        exelog.puts stderr
      end

    end

    # Dont rely on backup / backup_file from pulledpork to build tarball.
    def package
      cleanup = Dir["#{BASEDIR}/export/sensors/#{@sensor.name}_package.*.tgz"]
      tgz = Zlib::GzipWriter.new(File.open("#{BASEDIR}/export/sensors/#{@sensor.name}_package.#{@time_at}.tgz", 'wb'))
      Minitar.pack(Dir["#{BASEDIR}/export/sensors/#{@sensor.name}/*"], tgz) 
      FileUtils.cp("#{BASEDIR}/export/sensors/#{@sensor.name}_package.#{@time_at}.tgz", "#{BASEDIR}/archive/.")
      cleanup.each { |file| FileUtils.rm(file) }
    end

    def trigger_global (skipdownload='')
      FileUtils.mkdir_p("#{BASEDIR}/export/global")

      #Export files not processed by pulledpork
      ['threshold','whitelist'].each do |passthrough|
        FileUtils.cp("#{BASEDIR}/etc/global.#{passthrough}.conf", "#{BASEDIR}/export/global/#{passthrough}.conf")
      end

      # Pulled pork Exection notes:
      # -v Verbose output
      # -P Process even if no new downloads
      # -T Process text based rules files only, i.e. DO NOT process so_rules
      # -c use explicit config file
      stdout, stderr = shellex("#{@pulledpork_path} -v -P -T -c #{BASEDIR}/etc/global.pulledpork.conf #{skipdownload}")

      File.open("#{BASEDIR}/log/global_pulledpork.#{@time_at}.log", 'w') do |exelog|
        exelog.puts stdout
      end
      File.open("#{BASEDIR}/log/global_pulledpork.#{@time_at}.err", 'w') do |exelog|
        exelog.puts stderr
      end

    end

    
    def create_config_global
      configfile = File.open("#{BASEDIR}/etc/global.pulledpork.conf", 'w')
      configfile.puts "#Stat"
      configfile.puts "distro=#{@sensor.distro}"
      configfile.puts "snort_version=#{@sensor.snort_version}"
      configfile.puts "version=#{@pulledpork['version']}"
      configfile.puts "ignore=deleted.rules,experimental.rules"
      configfile.puts "sid_msg_version=1"
      configfile.puts ""
      @pulledpork['rules-urls'].each do |k,v|
        if v['explicit'] == true
          configfile.puts "rule_url=#{v['url']}"
        elsif v['oinkcode'] 
          configfile.puts "rule_url=#{v['url']}|#{@oinkcode}"
        end  
      end
      @pulledpork['ip-blacklists'].each do |url|
        configfile.puts "rule_url=#{url}|IPBLACKLIST|open"
      end
      configfile.puts "temp_path=#{BASEDIR}/tmp"
      configfile.puts ""
      configfile.puts "# Imports"
      configfile.puts "snort_path=/usr/local/bin/snort"
      configfile.puts "config_path=#{BASEDIR}/etc/snort.conf"
      configfile.puts ""
      configfile.puts "# Modifiers"
      configfile.puts "local_rules=#{BASEDIR}/etc/global.localrules.conf"
      configfile.puts "enablesid=#{BASEDIR}/etc/global.enablesid.conf"
      configfile.puts "dropsid=#{BASEDIR}/etc/global.dropsid.conf"
      configfile.puts "disablesid=#{BASEDIR}/etc/global.disablesid.conf"
      configfile.puts "modifysid=#{BASEDIR}/etc/global.modifysid.conf"
      configfile.puts ""
      configfile.puts "# Exports"
      configfile.puts "rule_path=#{BASEDIR}/export/global/snort.rules"
      configfile.puts "sid_msg=#{BASEDIR}/export/global/sid-msg.map"
      configfile.puts "# sorule_path=#{BASEDIR}/export/global/so_rules/"
      configfile.puts "sid_changelog=#{BASEDIR}/log/global_sid_changes.#{@time_at}.log"
      configfile.puts ""
      configfile.puts "# ClearText Combined IP Blacklist"
      configfile.puts "black_list=#{BASEDIR}/export/global/combined.blacklist"
      configfile.puts ""
      configfile.puts "# Path to output IPRVersion.dat"
      configfile.puts "IPRVersion=#{BASEDIR}/export/global/combined."
      configfile.puts ""
      configfile.puts "# Short circuit call to control bin"
      configfile.puts "snort_control=true"
      configfile.puts ""
      if @sensor.ips_policy 
        configfile.puts "# RuleSet (security, balanced, connectivity)"
        configfile.puts "ips_policy=#{@sensor.policy}"
        configfile.puts ""
      end  
      configfile.close

    end
    
      # Dont rely on backup / backup_file from pulledpork to build tarball.
    def package_global
      cleanup = Dir["#{BASEDIR}/export/global/*.md5"]
      cleanup.each { |file| FileUtils.rm(file) }
      tmp = Dir["#{BASEDIR}/export/global_package.*.tgz"]
      tgz = Zlib::GzipWriter.new(File.open("#{BASEDIR}/export/global_package.#{@time_at}.tgz", 'wb'))
      Minitar.pack(Dir["#{BASEDIR}/export/global/*"], tgz)
      Dir.glob("#{BASEDIR}/export/global/*").each do |globfile|
        begin 
          open("#{globfile}.md5", 'w') { |f| f.puts  Digest::MD5.file globfile }
        rescue Errno::ENOENT
        end
      end
      FileUtils.cp("#{BASEDIR}/export/global_package.#{@time_at}.tgz", "#{BASEDIR}/archive/.")
      tmp.each { |file| FileUtils.rm(file) }
    end

  end

end
