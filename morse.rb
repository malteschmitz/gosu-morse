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
  attr_reader :auto_cpm
  attr_accessor :speed
  attr_accessor :frequency
  attr_accessor :iambic_mode_b
  attr_accessor :swap_left_right
  attr_reader :pause
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
    @transmit_word = ""
    @transmit_code = ""
    @dit_length_history = []
    
    # configurable options
    @frequency = 660
    @speed = 200 # pixel movement per second
    @iambic_mode_b = false # false -> using mode B
    @cpm = 50
    
    @menu = Menu.new(self)
    @tree = Tree.new(self)
    @serial = SerialInterface.new(self)
    @text = Text.new(self)
  end

  def dit_length # in ms
    6000.0 / (@cpm)
  end

  def dit_or_dah 
    2 * dit_length
  end

  def dah_length
    3 * dit_length
  end
  alias letter_break dah_length

  def word_break
    7 * dit_length
  end

  def large_break
    5 * word_break
  end

  def move_history(history, delta, down)
    history.map! do |block|
      block[:pos] += @speed * delta / 1000.0
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
    delta = @now - @last_time
    @last_time = @now

    @menu.read_keyboard

    if @pause
      @stop_tone_at += delta if @stop_tone_at
      @next_at += delta if @next_at
      @last_tone_event += delta if @last_tone_event
    else
      @serial.read
      
      stop_tone if @stop_tone_at and @now > @stop_tone_at
      keyer_next if @now > @next_at
      
      decode_pause(@now - @last_tone_event) if !@sending and @last_tone_event
  
      move_history(@history, delta, @sending)
      move_history(@history_dit, delta, @dit_down)
      move_history(@history_dah, delta, @dah_down)
    end
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
    char = Gosu.button_id_to_char(id)
    if char.between?("a", "z") or char.between?("0", "9") or char == " "
      add_char(char)
    else
      case id
      when Gosu::KB_BACKSPACE
        delete_char
      when Gosu::KB_ESCAPE
        full_reset
      when Gosu::KB_RETURN
        start_tone unless @now <= @next_at
      when Gosu::KB_LEFT
        left_down
      when Gosu::KB_RIGHT
        right_down
      end
    end
  end

  def button_up(id)
    case id
    when Gosu::KB_RETURN
      stop_tone unless @now <= @next_at
    when Gosu::KB_LEFT
      left_up
    when Gosu::KB_RIGHT
      right_up
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

  def left_up
    if @swap_left_right
      dah_up
    else
      dit_up
    end
  end

  def left_down
    if @swap_left_right
      dah_down
    else
      dit_down
    end
  end

  def right_up
    if @swap_left_right
      dit_up
    else
      dah_up
    end
  end

  def right_down
    if @swap_left_right
      dit_down
    else
      dah_down
    end
  end

  def play_dit
    self.auto_cpm = false
    start_tone
    @stop_tone_at = @now + dit_length
    @next_at = @stop_tone_at + dit_length
    @dit_pressed = false
    @last_was_dah = false
  end

  def play_dah
    self.auto_cpm = false
    start_tone
    @stop_tone_at = @now + dah_length
    @next_at = @stop_tone_at + dit_length
    @dah_pressed = false
    @last_was_dah = true
  end

  def keyer_next
    @dah_pressed ||= @dah_down
    @dit_pressed ||= @dit_down
    if !@transmit_word.empty? or !@transmit_code.empty?
      transmit_next
    elsif @dah_pressed && @dit_pressed
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
    beep_on
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
    beep_off
    @sending = false
    @stop_tone_at = nil
    @last_tone_event = @now
  end

  def beep_on
    unless @channel and @channel.playing?
      volume = 1
      speed = @frequency * 1.0 / SAMPLE_FREQUENCY
      looping = true
      @channel = @sample.play(volume, speed, looping)
    end
  end

  def beep_off
    @channel.stop if @channel and @channel.playing?
  end

  def decode_tone(length)
    add_tone_length(length) if @auto_cpm
    if length > dit_or_dah
      @tree.go("-")
    else
      @tree.go(".")
    end
  end

  def decode_pause(length)
    if length > letter_break and !@decoded
      symbol = @tree.symbol
      symbol = "�" unless symbol
      write symbol
    end
    if length > large_break
      write "\n" if @decoded != "\n"
      @tree.reset
    elsif length > word_break
      write " " if @decoded != " "
    end
  end

  def auto_cpm=(val)
    @auto_cpm = val
    unless @auto_cpm
       @cpm = (@cpm * 1.0 / Menu::CPM_STEP).round * Menu::CPM_STEP
       @cpm = [[@cpm, Menu::CPM_MIN].max, Menu::CPM_MAX].min
    end
  end

  def add_tone_length(length)
    @dit_length_history.reject! { |e| @now - e[:time] > 7000 }
    @dit_length_history << {time: @now, length: length / 2.0}
    if @dit_length_history.size > 4
      average_dit_length = @dit_length_history.sum { |e| e[:length] } * 1.0 / (@dit_length_history.size)
      @cpm = (6000.0 / average_dit_length).round
      @cpm = [[@cpm, Menu::CPM_MIN].max, Menu::CPM_MAX].min
    end
  end

  def write(char)
    @text.text += char
    @text.preview = @text.preview[1..-1] unless @text.preview.empty?
    @text.highlighting = true
    @decoded = char
  end

  # . = dit
  # - = dah
  # d = dot break
  def get_code(char)
    if char == " "
      "dddd"
    elsif result = @tree.get_code(char)
      result + "ddd"
    end
  end

  def add_char(char)
    char.upcase!
    if @now > @next_at
      @transmit_code = get_code(char) if char != " "
      @text.preview = char
    else
      @transmit_word += char
      @text.preview += char
    end
  end

  def delete_char
    unless @transmit_word.empty?
      @transmit_word = @transmit_word[0..-2]
      @text.preview = @text.preview[0..-2] unless @text.preview.empty?
    end
  end

  def transmit_next
    if @transmit_code.empty?
      if !@transmit_word.empty?
        @transmit_code = get_code(@transmit_word[0])
        @transmit_word = @transmit_word[1..-1]
      end
    end
    symbol = @transmit_code[0]
    @transmit_code = @transmit_code[1..-1]
    case symbol
    when "."
      play_dit
    when "-"
      play_dah
    when "d"
      @next_at = @now + dit_length
    end
  end

  def full_reset
    @history = []
    @history_dit = []
    @history_dah = []
    @last_time = 0
    @next_at = 0
    @now = 0
    @transmit_word = ""
    @transmit_code = ""
    @channel.stop if @channel and @channel.playing?
    @sending = nil
    @stop_tone_at = nil
    @last_tone_event = nil
    @text.reset
    @tree.reset
  end

  def needs_cursor?
    not fullscreen?
  end

  def pause=(val)
    @pause = val
    if @pause
      beep_off
    else
      beep_on if @sending
    end
  end
end

Morse.new.show
