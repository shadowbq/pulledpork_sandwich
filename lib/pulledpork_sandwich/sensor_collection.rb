module Pulledpork_Sandwich

  class SensorCollection < Array

    def build( data, openvpn_log )
      self + data.collect { |sensor| 
        @sensor = Sensor.new
        @sensor.name = sensor[0]
        @sensor.hostname = sensor[1]["hostname"]
        @sensor.ipaddress = sensor[1]["ipaddress"]
        @sensor.notes = sensor[1]["notes"]
        @sensor.openvpn_log = openvpn_log
        @sensor
      }
    end

  end 

end