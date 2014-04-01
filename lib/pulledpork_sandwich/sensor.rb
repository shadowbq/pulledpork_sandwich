module Pulledpork_Sandwich

  class Sensor
    attr_accessor :name, :ipaddress, :notes, :hostname, :openvpn_log
    
    def openvpn
      raise ErrorSandwichConfig "Invalid openvpn log" unless (File.file?(openvpn_log) and File.exists?(openvpn_log))

      line = File.readlines(openvpn_log).select { |line| line =~ /#{hostname}/ }
      #raise "OpenVPN log search failure" unless line.first
      line[1].split(',').first
    end
    
  end

end