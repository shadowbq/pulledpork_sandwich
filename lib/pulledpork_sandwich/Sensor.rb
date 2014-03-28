module Pulledpork_Sandwich

  class Sensor
    attr_accessor :name, :ipaddress, :notes, :hostname
    
    def openvpn
      line = File.readlines(SandwichConf.instance.config['Config']['openvpn_log']).select { |line| line =~ /#{hostname}/ }
      #raise "OpenVPN log search failure" unless line.first
      line[1].split(',').first
    end
    
  end

end