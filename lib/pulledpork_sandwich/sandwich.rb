module Pulledpork_Sandwich

  # Provides a yaml configuration and validation for pulledpork_sandwich.
  class Sandwich

    def initialize (options)

      @verbose = options[:verbose]

      begin 
        raise ErrorSandwichConfig, "no such file: #{options[:sandwich_conf]}" unless (File.file?(options[:sandwich_conf]) and File.exists?(options[:sandwich_conf]))

        if options[:scaffold]
          # Read config for sensorname, if not fail and tell user to write config entry.
          puts "Scaffolding: #{options[:scaffold]}"
          @config = SandwichConf.new(options[:sandwich_conf])
          raise ErrorSandwichConfig, "no such sensor entry '#{options[:scaffold]}' in #{options[:sandwich_conf]}" if @config.config['SENSORS'][options[:scaffold]].nil?        
          # Proceed to scaffold sensor
          scaffold(options[:scaffold])
          exit 0
        elsif options[:purge]
          purge
          exit 0
        elsif options[:clobber]
          clobber
          exit 0
        else
          @config = SandwichConf.new(options[:sandwich_conf])
          depcheck
          @collection = SensorCollection.new
          
          if @config.config['CONFIG']['openvpn_log']
            @collection = @collection.build(@config.config['CONFIG'],@config.config['SENSORS'], @config.config['CONFIG']['openvpn_log']) 
          else
            @collection = @collection.build(@config.config['CONFIG'],@config.config['SENSORS']) 
          end

          @collection.each do |sensor| 
            pulledpork(sensor, @config.config['CONFIG']['oinkcode'], @config.config['CONFIG']['pulledpork'], options[:skipdownload])
          end
        end 
      
      rescue ErrorSandwichConfig => e
          puts "\n[Config Error] #{e.message}"
          puts "Please refer to documentation on: www.github.com/shadowbq/pulledpork_sandwich"
          exit 1
      rescue ShellExecutionError => e
          if /Error 403/ =~ e.message
            puts "\n[Dependency Error] Authentication Issue raised. Check Oinkcodes."
          else
            puts "\n[Dependency Error] #{e.message}"
          end
          puts "Please refer to documentation on: www.github.com/shadowbq/pulledpork_sandwich"
          exit 1    
      end  

    end # def

    private

    ## Helpers
    def verbose(msg)
      print msg if @verbose 
    end

    def depcheck
      raise ShellExecutionError, "no such file: pulledpork.pl" unless which ('pulledpork.pl')
    end

    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable? exe
        }
      end
      return nil
    end

    
    ## Sensor loop
    def pulledpork(sensor, oinkcode, pulledporkconf, skipdownload)
      verbose "Sensor - #{sensor.name} :"
      #check for scaffold of sensor.
      # Read config for sensorname, if not fail and tell user to write config entry.

      pork = SandwichWrapper.new(sensor, oinkcode, pulledporkconf)

      #Merge Global Policy with Sensor Policy
      verbose "m"
      pork.combine_modifiers
      verbose "."  
      
      #Dynamic Create PulledPork Config to file
      verbose "p"  
      pork.create_config
      verbose "."  

      #Run Pulled Pork for each Sensor
      verbose "r"  
      if skipdownload 
        pork.trigger('-n') 
      else   
        pork.trigger
      end  
      verbose "."  

      #TAR.GZ results 
      verbose "z"  
      pork.package
      verbose "." 

      #SCP to corresponding sensor
      #puts "SCPing to #{sensor.hostname} - #{sensor.openvpn}"
      #Net::SCP.upload!("remote.host.com", "username", "/local/path", "/remote/path", :ssh => { :password => "password" })

      verbose "done\n"
    end

    #Make all the skelton directory for the sensor
    def scaffold(sensor)
      
      verbose "Scaffolding: Checking Application Directory Structure \n"
      FileUtils.mkdir_p("#{BASEDIR}/log")
      FileUtils.mkdir_p("#{BASEDIR}/tmp")
      FileUtils.mkdir_p("#{BASEDIR}/archive")
      FileUtils.mkdir_p("#{BASEDIR}/etc/sensors")
      
      #Possible NO-OP      
      unless (File.file?("#{BASEDIR}/etc/global.disablesid.conf") and File.exists?("#{BASEDIR}/etc/global.disablesid.conf"))
        verbose "Scaffolding: Creating Global Configurations \n"
        FileUtils.cp_r(Dir.glob("#{BASEDIR}/defaults/global.*.conf"), "#{BASEDIR}/etc/") 
      end  

      unless (File.file?("#{BASEDIR}/etc/sensors/#{sensor}/disablesid.conf") and File.exists?("#{BASEDIR}/etc/sensors/#{sensor}/disablesid.conf"))
        verbose "Scaffolding: Creating #{sensor} Sensor Configurations \n"
        FileUtils.cp_r("#{BASEDIR}/defaults/sensors/Sample/", "#{BASEDIR}/etc/sensors/#{sensor}")
      end  
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{sensor}")
      #FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{sensor}/so_rules/")
      #FileUtils.touch("#{BASEDIR}/export/sensors/#{sensor}/so_rules.rules")
      #FileUtils.touch("#{BASEDIR}/log/#{sensor}_sid_changes.log")
    end

    def purge
      begin
        FileUtils.remove_entry_secure("#{BASEDIR}/log")
      rescue Errno::ENOENT
      end
      
      begin
        FileUtils.remove_entry_secure("#{BASEDIR}/tmp")
      rescue Errno::ENOENT
      end

      FileUtils.mkdir_p("#{BASEDIR}/log")
      FileUtils.mkdir_p("#{BASEDIR}/tmp")
    end

    def clobber
      purge
      begin
        FileUtils.remove_entry_secure("#{BASEDIR}/archive")
      rescue Errno::ENOENT
      end

      begin
        FileUtils.remove_entry_secure("#{BASEDIR}/export/sensors")
      rescue Errno::ENOENT
      end  
      
      FileUtils.mkdir_p("#{BASEDIR}/archive")
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors")
    end

  end
end
