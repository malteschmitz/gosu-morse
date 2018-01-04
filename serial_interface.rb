require 'rubyserial'

class SerialInterface
  LEFT_COMMAND = 65
  RIGHT_COMMAND = 70
  DOWN_COMMAND = 0
  UP_COMMAND = 1
  SERIAL_PORT = '/dev/cu.usbmodem1421'
  SERIAL_BAUD = 115200

  def initialize(morse)
    @morse = morse
    @port = begin
      Serial.new(SERIAL_PORT, SERIAL_BAUD)
    rescue RubySerial::Error
      nil
    end
    if @port
      puts "Opened Serial port #{SERIAL_PORT}"
    else
      puts "Error opening serial port #{SERIAL_PORT}"
    end
  end

  def read
    if @port
      c = @port.getbyte
      case c
      when LEFT_COMMAND + UP_COMMAND
        @morse.left_up
      when LEFT_COMMAND + DOWN_COMMAND
        @morse.left_down
      when RIGHT_COMMAND + UP_COMMAND
        @morse.right_up
      when RIGHT_COMMAND + DOWN_COMMAND
        @morse.right_down
      end
    end
  end
end