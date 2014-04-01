
require 'optparse'

module Pulledpork_Sandwich
  Pulledpork_Sandwich::BASEDIR = '/opt/pulledpork_sandwich'

  class CLI

    def self.invoke
      self.new
    end
    
    def initialize
      
      options = {}
      
      options[:scaffold] = nil
      options[:nopush] = false
      options[:sandwich_conf] = "#{BASEDIR}/etc/sandwich.conf"
      options[:verbose] = false # Fix Sandwich Conf loading order.. 
      
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
      
      begin 
        raise ErrorSandwichConfig, "no such file: #{options[:sandwich_conf]}" unless (File.file?(options[:sandwich_conf]) and File.exists?(options[:sandwich_conf]))

        unless options[:scaffold].nil? 
          # Read config for sensorname, if not fail and tell user to write config entry.

          @config = SandwichConf.new(options[:sandwich_conf])
          raise ErrorSandwichConfig, "no such sensor entry in #{options[:sandwich_conf]}" unless @config.config['SENSORS'][options[:scaffold]].exists?        
          # Proceed to scaffold sensor
          scaffold(options[:scaffold])
          exit 0
        end  
        
        if options[:scaffold].nil? 
          @config = SandwichConf.new(options[:sandwich_conf])
          @collection = SensorCollection.new
          @collection = @collection.build(@config.config['SENSORS'], @config.config['Config']['openvpn_log']) 

          @collection.each do  |sensor| 
            pulledpork(sensor)
          end
        end
      
      rescue ErrorSandwichConfig => e
          puts "[Config Error] #{e.message}"
          puts "Please refer to documentation on: www.github.com/shadowbq/pulledpork_sandwich"
          exit 1
      end  

    end # def

    private

    def pulledpork(sensor)
      print "Sensor - #{sensor.name} :" if verbose 

      #check for scaffold of sensor.
      # Read config for sensorname, if not fail and tell user to write config entry.

      pork = SandwichWrapper.new(sensor.name)

      #Merge Global Policy with Sensor Policy
      print "m" if verbose 
      pork.combine_modifiers
      print "." if verbose 
      
      #Dynamic Create PulledPork Config to file
      print "p"
      pork.create_config
      print "." if verbose 

      #Run Pulled Pork for each Sensor
      print "r" if verbose 
      pork.trigger
      print "." if verbose 

      #TAR.GZ results 
      print "z" if verbose 
      pork.package
      puts "." if verbose

      #SCP to corresponding sensor
      #puts "SCPing to #{sensor.hostname} - #{sensor.openvpn}"
      #Net::SCP.upload!("remote.host.com", "username", "/local/path", "/remote/path", :ssh => { :password => "password" })
    end

    #Make all the skelton directory for the sensor
    def scaffold(sensor)
      FileUtils.mkdir_p("#{BASEDIR}/logs")
      FileUtils.mkdir_p("#{BASEDIR}/tmp")
      FileUtils.mkdir_p("#{BASEDIR}/archive")
      FileUtils.cp_r(Dir.glob("#{BASEDIR}/defaults/*.conf"), "#{BASEDIR}/etc/sensors/#{sensor}") unless File.directory?("#{BASEDIR}/etc/")
      FileUtils.mkdir_p("#{BASEDIR}/etc/sensors")
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{options[:scaffold]}")
      FileUtils.cp_r("#{BASEDIR}/defaults/sensors/Sample/", "#{BASEDIR}/etc/sensors/#{options[:scaffold]}")
      FileUtils.mkdir_p("#{BASEDIR}/export/sensors/#{options[:scaffold]}/so_rules/")
      FileUtils.touch("#{BASEDIR}/export/sensors/#{options[:scaffold]}/so_rules.rules")
    end

  end
end
