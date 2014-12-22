module Pulledpork_Sandwich
  
  # This class wraps the execution of pulledpork.pl per sensor,
  # the creation of each of the pulledpork.conf files, and
  # the packaging of the results into a tar-gz ball.
  class SandwichWrapper

    def initialize(sensor, oinkcode, pulledpork)
      @sensor = sensor
      @oinkcode = oinkcode
      @pulledpork = pulledpork
      @time_at = Time.now.to_i
    end

    def combine_modifiers
      modifiers = ['localrules','enablesid','dropsid', 'disablesid', 'modifysid','threshold']

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
           tmpfile.unlink   # deletes the temp file
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
          configfile.puts "rule_url=#{v['url']}|blank"
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
      
      #Export threshold.conf as it is not processed by pulledpork
      FileUtils.cp("#{BASEDIR}/etc/sensors/#{@sensor.name}/combined/threshold.conf", "#{BASEDIR}/export/sensors/#{@sensor.name}/threshold.conf")
      
      # Pulled pork Exection notes: 
      # -v Verbose output 
      # -P Process even if no new downloads
      # -T Process text based rules files only, i.e. DO NOT process so_rules
      # -c use explicit config file
      stdout, stderr = shellex("pulledpork.pl -v -P -T -c #{BASEDIR}/etc/sensors/#{@sensor.name}/pulledpork.dyn.conf #{skipdownload}")

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

  end

end
