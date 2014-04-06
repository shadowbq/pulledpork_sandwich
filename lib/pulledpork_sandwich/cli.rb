
require 'optparse'

module Pulledpork_Sandwich
  Pulledpork_Sandwich::BASEDIR = '/opt/pulledpork_sandwich'

  class CLI

    def self.invoke
      self.new
    end
    
    def initialize
      
      @verbose = false
      options = {}
      
      options[:scaffold] = nil
      options[:nopush] = false
      options[:sandwich_conf] = "#{BASEDIR}/etc/sandwich.conf"
      options[:verbose] = @verbose # Fix Sandwich Conf loading order.. 
      
      opt_parser = OptionParser.new do |opt|
        opt.banner = "Usage: pulledpork_sandwich [OPTIONS] "
        opt.separator ""

        opt.separator "Alt Modes::"
        
        opt.on("-s","--scaffold=","scaffold a configuration for a sensor named xxx") do |value|
          options[:scaffold] = value
        end
        
        opt.separator "Options::"

        opt.on("-n", "--nopush", "Do not push / scp configurations") do 
          options[:nopush] = false
        end
        
        opt.on("-c","--config=","location of sandwich.conf file","  Default: #{options[:sandwich_conf]}") do |value|
          options[:sandwich_conf] = value
        end

        opt.on("-v", "--verbose", "Run verbosely") do 
          options[:verbose] = true
        end
  
        opt.on_tail("-h","--help","Display this screen") do
          puts opt_parser
          exit 0
        end
        
      end

      #Verify the options
      begin
        raise unless ARGV.size > 0
        opt_parser.parse!
      #If options fail display help
      #rescue Exception => e  
      #  puts e.message  
      #  puts e.backtrace.inspect  
      rescue 
        puts opt_parser
        exit
      end

      @verbose = options[:verbose]

      begin 
        raise ErrorSandwichConfig, "no such file: #{options[:sandwich_conf]}" unless (File.file?(options[:sandwich_conf]) and File.exists?(options[:sandwich_conf]))

        if options[:scaffold].nil? 
          @config = SandwichConf.new(options[:sandwich_conf])
          depcheck
          @collection = SensorCollection.new
          
          if @config.config['CONFIG']['openvpn_log']
            @collection = @collection.build(@config.config['SENSORS'], @config.config['CONFIG']['openvpn_log']) 
          else
            @collection = @collection.build(@config.config['SENSORS']) 
          end

          @collection.each do  |sensor| 
            pulledpork(sensor, @config.config['CONFIG']['oinkcode'])
          end
        else
          # Read config for sensorname, if not fail and tell user to write config entry.
          puts "Scaffolding: #{options[:scaffold]}"
          @config = SandwichConf.new(options[:sandwich_conf])
          raise ErrorSandwichConfig, "no such sensor entry '#{options[:scaffold]}' in #{options[:sandwich_conf]}" if @config.config['SENSORS'][options[:scaffold]].nil?        
          # Proceed to scaffold sensor
          scaffold(options[:scaffold])
          exit 0
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

    def pulledpork(sensor, oinkcode)
      verbose "Sensor - #{sensor.name} :"
      #check for scaffold of sensor.
      # Read config for sensorname, if not fail and tell user to write config entry.

      pork = SandwichWrapper.new(sensor.name, oinkcode)

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
      pork.trigger
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
      
      #Possible NO-OP
      
      unless (File.file?("#{BASEDIR}/etc/global.disablesid.conf") and File.exists?("#{BASEDIR}/etc/global.disablesid.conf"))
        verbose "Scaffolding: Global configurations \n"
        FileUtils.cp_r(Dir.glob("#{BASEDIR}/defaults/global.*.conf"), "#{BASEDIR}/etc/") 
      end  
      FileUtils.mkdir_p("#{BASEDIR}/logs")
      FileUtils.mkdir_p("#{BASEDIR}/tmp")
      FileUtils.mkdir_p("#{BASEDIR}/archive")
      FileUtils.mkdir_p("#{BASEDIR}/etc/sensors")

      verbose "Scaffolding: #{sensor} \n"
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{sensor}")
      FileUtils.cp_r("#{BASEDIR}/defaults/sensors/Sample/", "#{BASEDIR}/etc/sensors/#{sensor}")
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{sensor}/so_rules/")
      FileUtils.touch("#{BASEDIR}/export/sensors/#{sensor}/so_rules.rules")
    end

  end
end
