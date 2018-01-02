require 'gosu'
require 'rubyserial'

class Morse < Gosu::Window
  SAMPLE_FREQUENCY = 440
  WIDTH = 1600
  HEIGHT = 900
  # pixel movement per millisecond
  SPEED = 1

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Morse"
    @color = Gosu::Color.new(255, 255, 255, 255)
    @sample = Gosu::Sample.new("440.wav")
    @frequency = 660
    @history = []
    @history_dit = []
    @history_dah = []
    @last_time = Gosu::milliseconds()
    @next_at = 0
    @stop_tone_at = 0
    @iambic = :mode_a # :mode_b

    @cpm = 50
  end

  def micros
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) / 1000.0
  end

  def dit_length # in us
    6.0 / (@cpm) * 1000000
  end

  def dit_or_dash 
    2 * dit_length
  end

  def dah_length
    3 * dit_length
  end
  alias letter_break dah_length

  def word_break
    7 * dit_length
  end

  def move_history(history, delta, down)
    history.map! do |block|
      block[:pos] += SPEED * delta
      block
    end
    history.reject!{ |block| block[:pos] > WIDTH }
    if down and not history.empty?
      history.last[:width] += history.last[:pos]
      history.last[:pos] = 0
    end
  end

  def update
    delta = Gosu::milliseconds() - @last_time
    @last_time = Gosu::milliseconds()
    move_history(@history, delta, @sending)
    move_history(@history_dit, delta, @dit_down)
    move_history(@history_dah, delta, @dah_down)
  end

  def draw_history(history, y, height)
    history.each do |block|
      Gosu.draw_rect(block[:pos], y, block[:width], height, @color)
    end
  end

  def draw
    draw_history(@history, 100, 30)
    draw_history(@history_dit, 140, 10)
    draw_history(@history_dah, 160, 10)
  end

  # def button_down(id)
  #   if id == Gosu::KB_SPACE
  #     start_tone
  #   else
  #     super
  #   end
  # end

  # def button_up(id)
  #   if id == Gosu::KB_SPACE
  #     stop_tone
  #   else
  #     super
  #   end
  # end
  
  def dit_up
    @dit_down = false
    @dit_pressed = false if @iambic == :mode_a
  end

  def dit_down
    @dit_down = true
    @dit_pressed = true
    @history_dit << {width: 0, pos: 0}
  end

  def dah_up
    @dah_down = false
    @dah_pressed = false if @iambic == :mode_a
  end

  def dah_down
    @dah_down = true
    @dah_pressed = true
    @history_dah << {width: 0, pos: 0}
  end

  def play_dit
    start_tone
    @stop_tone_at = micros + dit_length
    @next_at = @stop_tone_at + dit_length
    @dit_pressed = false
    @last_was_dah = false
  end

  def play_dah
    start_tone
    @stop_tone_at = micros + dah_length
    @next_at = @stop_tone_at + dit_length
    @dah_pressed = false
    @last_was_dah = true
  end

  def keyer_next
    @dah_pressed ||= @dah_down
    @dit_pressed ||= @dit_down
    if @dah_pressed && @dit_pressed
      if @last_was_dah
        play_dit
      else
        play_dah
      end
    elsif @dah_pressed
      play_dah
    elsif @dit_pressed
      play_dit
    end
  end

  def keyer_tick
    stop_tone if micros > @stop_tone_at
    keyer_next if micros > @next_at
  end

  def start_tone
    unless @channel and @channel.playing?
      volume = 1
      speed = @frequency * 1.0 / SAMPLE_FREQUENCY
      looping = true
      @channel = @sample.play(volume, speed, looping)
    end
    @sending = true
    @history << {width: 0, pos: 0}
  end

  def stop_tone
    if @channel and @channel.playing?
      @channel.stop
    end
    @sending = false
  end
end

$morse = Morse.new

LEFT_COMMAND = 65
RIGHT_COMMAND = 70
DOWN_COMMAND = 0
UP_COMMAND = 1
SERIAL_PORT = '/dev/cu.usbmodem1421'
SERIAL_BAUD = 115200

Thread.abort_on_exception=true
serialThread = Thread.new do
  port = Serial.new(SERIAL_PORT, SERIAL_BAUD)
  loop do
    c = port.getbyte
    case c
    when LEFT_COMMAND + UP_COMMAND
      $morse.dit_up
    when LEFT_COMMAND + DOWN_COMMAND
      $morse.dit_down
    when RIGHT_COMMAND + UP_COMMAND
      $morse.dah_up
    when RIGHT_COMMAND + DOWN_COMMAND
      $morse.dah_down
    end
    $morse.keyer_tick
    #sleep 0.01
  end
end

$morse.show
serialThread.exit
