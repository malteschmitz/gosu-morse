require 'gosu'
require 'rpi_gpio'
require_relative 'settings'

RPi::GPIO.set_numbering :bcm
RPi::GPIO.setup Settings::PIN_MORSE_KEY, :as => :input, :pull => :up
RPi::GPIO.setup Settings::PIN_LEFT_PADDLE, :as => :input, :pull => :up
RPi::GPIO.setup Settings::PIN_RIGHT_PADDLE, :as => :input, :pull => :up

sample = Gosu::Sample.new("440.wav")
channel = nil
volume = 1
speed = 1
looping = true

pin_morse = false

loop do
  new_morse = RPi::GPIO.high? Settings::PIN_MORSE_KEY
  if pin_morse and not new_morse
    if not channel
      channel = sample.play(volume, speed, looping)
      puts "START"
    end
  elsif not pin_morse and new_morse
    if channel
      channel.stop
      channel = nil
      puts "stop"
    end
  end
  pin_morse = new_morse
end
