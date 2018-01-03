require 'gosu'
require 'rubyserial'
require_relative 'menu'
require_relative 'tree'
require_relative 'colors'

class Morse < Gosu::Window
  SAMPLE_FREQUENCY = 440
  WIDTH = 1600
  HEIGHT = 900

  LEFT_COMMAND = 65
  RIGHT_COMMAND = 70
  DOWN_COMMAND = 0
  UP_COMMAND = 1
  SERIAL_PORT = '/dev/cu.usbmodem1421'
  SERIAL_BAUD = 115200

  attr_accessor :cpm
  attr_accessor :speed
  attr_accessor :frequency
  attr_accessor :iambic_mode_b
  attr_reader :now

  def initialize
    super WIDTH, HEIGHT #, true
    self.caption = "Morse Code Visualizer"
    @sample = Gosu::Sample.new("440.wav")
    @history = []
    @history_dit = []
    @history_dah = []
    @last_time = 0
    @next_at = 0
    @now = 0
    @port = Serial.new(SERIAL_PORT, SERIAL_BAUD)

    # configurable options
    @frequency = 660
    @speed = 1000 # pixel movement per second
    @iambic_mode_b = false # false -> using mode B
    @cpm = 50
    
    @menu = Menu.new(self)
    @tree = Tree.new(self)   
  end

  def dit_length # in ms
    6.0 / (@cpm) * 1000
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
      block[:pos] += @speed * delta / 1000
      block
    end
    history.reject!{ |block| block[:pos] > WIDTH }
    if down and not history.empty?
      history.last[:width] += history.last[:pos]
      history.last[:pos] = 0
    end
  end

  def read_serial
    c = @port.getbyte
    case c
    when LEFT_COMMAND + UP_COMMAND
      left_up
    when LEFT_COMMAND + DOWN_COMMAND
      left_down
    when RIGHT_COMMAND + UP_COMMAND
      right_up
    when RIGHT_COMMAND + DOWN_COMMAND
      right_down
    end
  end

  def update
    @now = Gosu::milliseconds()
    read_serial
    @menu.read_keyboard
    
    stop_tone if @stop_tone_at and @now > @stop_tone_at
    keyer_next if @now > @next_at
    
    delta = @now - @last_time
    @last_time = @now
    move_history(@history, delta, @sending)
    move_history(@history_dit, delta, @dit_down)
    move_history(@history_dah, delta, @dah_down)
  end

  def draw_history(history, y, height)
    history.each do |block|
      Gosu.draw_rect(block[:pos], y, block[:width], height, yield(block))
    end
  end

  def draw
    draw_history(@history, 100, 30) do |block|
      duration = block[:width] * 1000 / @speed
      duration = [[duration, dit_length].max, dah_length].min
      p = (duration - dit_length) / (dah_length - dit_length)
      Colors::mix(Colors::DIT, Colors::DAH, p)
    end
    draw_history(@history_dit, 140, 4) { Colors::DIT }
    draw_history(@history_dah, 150, 4) { Colors::DAH }
    @menu.draw
    @tree.draw
  end

  def button_down(id)
    case id
    when Gosu::KB_SPACE
      start_tone
    when Gosu::KB_LEFT
      left_down
    when Gosu::KB_RIGHT
      right_down
    else
      super
    end
  end

  def button_up(id)
    case id
    when Gosu::KB_SPACE
      stop_tone
    when Gosu::KB_LEFT
      left_up
    when Gosu::KB_RIGHT
      right_up
    else
      super
    end
  end
  
  def dit_up
    @dit_down = false
    @dit_pressed = false unless @iambic_mode_b
  end

  def dit_down
    @dit_down = true
    @dit_pressed = true
    @history_dit << {width: 0, pos: 0}
  end

  def dah_up
    @dah_down = false
    @dah_pressed = false unless @iambic_mode_b
  end

  def dah_down
    @dah_down = true
    @dah_pressed = true
    @history_dah << {width: 0, pos: 0}
  end

  alias left_up dit_up
  alias left_down dit_down
  alias right_up dah_up
  alias right_down dah_down

  def play_dit
    start_tone
    @stop_tone_at = @now + dit_length
    @next_at = @stop_tone_at + dit_length
    @dit_pressed = false
    @last_was_dah = false
  end

  def play_dah
    start_tone
    @stop_tone_at = @now + dah_length
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
    @stop_tone_at = nil
  end
end

Morse.new.show
