require 'rpi_gpio'

puts 'Hello'

RPi::GPIO.set_numbering :bcm

RPi::GPIO.setup 23, :as => :input, :pull => :up
RPi::GPIO.setup 24, :as => :input, :pull => :up
RPi::GPIO.setup 25, :as => :input, :pull => :up

# RPi::GPIO.watch [23,24,25], :on => :both do |pin, value|
#   puts "#{pin}: #{value}"
# end

loop do
  pin23 = RPi::GPIO.high? 23
  pin24 = RPi::GPIO.high? 24
  pin25 = RPi::GPIO.high? 25
  puts "23: #{pin23 ? '1' : '0'}  24: #{pin24 ? '1' : '0'}  25: #{pin25 ? '1' : '0'}"
  sleep 0.1
end

RPi::GPIO.clean_up
