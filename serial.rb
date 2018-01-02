require "rubyserial"

port = Serial.new('/dev/cu.usbmodem1421', 115200)

loop do
  c = port.getbyte
  p c if c
  sleep 0.01
end
