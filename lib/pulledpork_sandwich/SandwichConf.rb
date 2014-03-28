module Pulledpork_Sandwich

	class SandwichConf

	  include Singleton
	 
	  attr_reader :config

	  def initialize(config_file)
	    @config = YAML.load_file(config_file)
	    raise EmptySandwichConfig, "Missing defined sensors)" unless @config['SENSORS'].nil?

	    @config['SENSORS'].each_key do |host|
	      @config['SENSORS'][host]['notes'] ||= ""
	      @config['SENSORS'][host]['tags'] ||= []
	      RuntimeError.new("Missing hostname: (#{host})")  unless @config['SENSORS'][host].include? "hostname" 
	      RuntimeError.new("Missing ipaddress: (#{host})")  unless @config['SENSORS'][host].include? "ipaddress" 
	    end

	    #check to see if this host has a hypervisor 
	    RuntimeError.new("Missing oinkmaster code")  unless @config['CONFIG'].include? "oinkcode" 
	    @config['CONFIG']['debug'] ||= false
	    @config['CONFIG']['verbose'] ||= false
	    @config['CONFIG']['openvpnlog'] ||= false

	    @config
	  end
	 
	end

end