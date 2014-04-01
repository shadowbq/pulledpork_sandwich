module Pulledpork_Sandwich

	class SandwichConf

	  attr_reader :config

	  def initialize(config_file)
	    @config = YAML.load_file(config_file)

	    raise ErrorSandwichConfig, "Empty configuration file: #{config_file}" unless @config
	    raise ErrorSandwichConfig, "Missing section SENSORS: #{config_file}" unless @config.keys.include?('SENSORS')
	    raise ErrorSandwichConfig, "No hosts entries in SENSORS: #{config_file}" if @config['SENSORS'].nil?

	    @config['SENSORS'].each_key do |host|
	      @config['SENSORS'][host]['notes'] ||= ""
	      @config['SENSORS'][host]['tags'] ||= []
	      raise ErrorSandwichConfig "Missing hostname: (#{host}) in configuration" unless @config['SENSORS'][host].include? "hostname" 
	      raise ErrorSandwichConfig "Missing ipaddress: (#{host}) in configuration" unless @config['SENSORS'][host].include? "ipaddress" 
	    end

	    #check to see if this host has a hypervisor 
	    raise ErrorSandwichConfig "Missing oinkmaster code"  unless @config['CONFIG'].include? "oinkcode" 
	    @config['CONFIG']['debug'] ||= false
	    @config['CONFIG']['verbose'] ||= false
	    @config['CONFIG']['openvpnlog'] ||= false

	    @config
	  end
	 
	end

end