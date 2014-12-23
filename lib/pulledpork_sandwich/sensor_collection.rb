module Pulledpork_Sandwich

  class SensorCollection < Array

    def build( global, local, openvpn_log = nil )
      self + local.collect { |sensor| 
        @sensor = Sensor.new
        @sensor.name = sensor[0]
        @sensor.hostname = sensor[1]["hostname"]
        @sensor.ipaddress = sensor[1]["ipaddress"]
        @sensor.notes = sensor[1]["notes"]
        @sensor.snort_version = sensor[1]["snort_version"]
        @sensor.distro = sensor[1]["distro"]
        @sensor.openvpn_log = openvpn_log
        @sensor
      }
    end

  end 

end
