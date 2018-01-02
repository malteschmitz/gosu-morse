require "serialport"

port = SerialPort.new('/dev/cu.usbmodem1421', 115200)

loop do
  c = port.getc
  p c
end
