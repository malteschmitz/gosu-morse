require 'gosu'
require_relative 'menu'
require_relative 'tree'
require_relative 'colors'
require_relative 'serial_interface'
require_relative 'text'

class Morse < Gosu::Window
  SAMPLE_FREQUENCY = 440
  WIDTH = 1600
  HEIGHT = 900
  HISTORY_POSITION = 345

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
    
    # configurable options
    @frequency = 660
    @speed = 1000 # pixel movement per second
    @iambic_mode_b = false # false -> using mode B
    @cpm = 50
    
    @menu = Menu.new(self)
    @tree = Tree.new(self)
    @serial = SerialInterface.new(self)
    @text = Text.new(self)
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

  def word_break_detection
    word_break + dit_length
  end

  def letter_break_detection
    letter_break + dit_length
  end

  def large_break_detection
    5 * word_break_detection
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

  def update
    @now = Gosu::milliseconds()
    @serial.read
    @menu.read_keyboard
    
    stop_tone if @stop_tone_at and @now > @stop_tone_at
    keyer_next if @now > @next_at
    
    decode_pause(@now - @last_tone_event) if !@sending and @last_tone_event

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
    draw_history(@history, HISTORY_POSITION, 30) do |block|
      duration = block[:width] * 1000 / @speed
      duration = [[duration, dit_length].max, dah_length].min
      p = (duration - dit_length) / (dah_length - dit_length)
      Colors::mix(Colors::DIT_ACTIVE, Colors::DAH_ACTIVE, p)
    end
    draw_history(@history_dit, HISTORY_POSITION + 40, 4) { Colors::DIT_ACTIVE }
    draw_history(@history_dah, HISTORY_POSITION + 50, 4) { Colors::DAH_ACTIVE }
    @menu.draw
    @tree.draw
    @text.draw
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
    if @decoded
      @decoded = nil
      @tree.reset
      @text.highlighting = false
    end
    @last_tone_event = @now
    @history << {width: 0, pos: 0}
  end

  def stop_tone
    decode_tone(@now - @last_tone_event) if @last_tone_event
    if @channel and @channel.playing?
      @channel.stop
    end
    @sending = false
    @stop_tone_at = nil
    @last_tone_event = @now
  end

  def decode_tone(pause)
    if pause > dit_or_dash
      @tree.go("-")
    else
      @tree.go(".")
    end
  end

  def decode_pause(pause)
    if pause > letter_break_detection and !@decoded
      symbol = @tree.symbol
      symbol = "�" unless symbol
      write symbol
    end
    if pause > large_break_detection
      write "\n" if @decoded != "\n"
      @tree.reset
    elsif pause > word_break_detection
      write " " if @decoded != " "
    end
  end

  def write(char)
    @text.text += char
    @text.highlighting = true
    @decoded = char
  end
end

Morse.new.show
