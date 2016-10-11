
require 'optparse'

module Pulledpork_Sandwich
  Pulledpork_Sandwich::BASEDIR = '/opt/pulledpork_sandwich'

  class CLI

    def self.invoke
      self.new
    end
    
    def initialize
      
      options = {}
      
      options[:skipdownload] = false
      options[:nopush] = false
      options[:sandwich_conf] = "#{BASEDIR}/etc/sandwich.conf"
      options[:verbose] = false
      
      opt_parser = OptionParser.new do |opt|
        opt.banner = "Usage: pulledpork_sandwich [OPTIONS] "
        opt.separator ""

       
        opt.separator "Deployment Modes::"
        
        opt.on("-n", "--nopush", "Do not push via scp the new packages","  Default: #{options[:nopush]}") do 
          options[:nopush] = false
        end
        
        opt.separator ""
        opt.separator "Options::"
        
        opt.on("-k", "--keep", "Keep existing rules, aka do not download new rules from rules sources","  Default: #{options[:skipdownload]}") do 
          options[:skipdownload] = true
        end
      
        opt.on("-c","--config=","Location of sandwich.conf file","  Default: #{options[:sandwich_conf]}") do |value|
          options[:sandwich_conf] = value
        end

        opt.on("-v", "--verbose", "Run verbosely") do 
          options[:verbose] = true
        end
  
        opt.on_tail("-h","--help","Display this screen") do
          puts opt_parser
          exit 0
        end

        opt.separator ""
        opt.separator "Alt Modes::"
        
        opt.on("-s","--scaffold=","scaffold a configuration for a sensor named xxx") do |value|
          options[:scaffold] = value
        end


        opt.on("-g","--global-only","Only run pulledpork_sandwich for global configuration") do 
          options[:global] = true
        end


        opt.on("--purge","Deletes log, tmp") do
          options[:purge] = true
        end

        opt.on("--clobber","Deletes log, tmp, archive, and export") do 
          options[:clobber] = true
        end
        
      end

      #Verify the options
      begin
        raise unless ARGV.size > 0
        opt_parser.parse!
        exclusive_options = [:scaffold, :purge, :clobber, :global]

        if (exclusive_options.collect { |item| item if options.include? item }.compact).length > 1
          puts "Error: Mutually Exclusive options were selected"
          puts optparse
          exit
        end
      #If options fail display help
      #rescue Exception => e  
      #  puts e.message  
      #  puts e.backtrace.inspect  
      rescue 
        puts opt_parser
        exit
      end
    
      Sandwich.new(options)
    end

  end

end
