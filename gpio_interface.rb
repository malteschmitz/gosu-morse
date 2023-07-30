require 'rpi_gpio'

class GpioInterface
  def initialize(morse)
    @morse = morse
    
    RPi::GPIO.set_numbering :bcm
    RPi::GPIO.setup Settings::PIN_MORSE_KEY, :as => :input, :pull => :up
    RPi::GPIO.setup Settings::PIN_LEFT_PADDLE, :as => :input, :pull => :up
    RPi::GPIO.setup Settings::PIN_RIGHT_PADDE, :as => :input, :pull => :up
    
    @pin_morse = true
    @pin_left = true
    @pin_right = true
  end

  def read
    read_morse
    read_left
    read_right
  end

  def read_morse
    new_morse = RPi::GPIO.high? Settings::PIN_MORSE_KEY
    if @pin_morse and not new_morse
      @morse.morse_key_down
    elsif not @pin_morse and new_morse
      @morse.morse_key_up
    end
    @pin_morse = new_morse
  end

  def read_left
    new_left = RPi::GPIO.high? Settings::PIN_LEFT_PADDLE
    if @pin_left and not new_left
      @morse.left_down
    elsif not @pin_left and new_left
      @morse.left_up
    end
    @pin_left = new_left
  end

  def read_right
    new_right = RPi::GPIO.high? Settings::PIN_RIGHT_PADDLE
    if @pin_right and not new_right
      @morse.right_down
    elsif not @pin_right and new_right
      @morse.right_up
    end
    @pin_right = new_right
  end
end