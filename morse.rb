require 'gosu'

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
    @down = false
    @frequency = 660
    @history = []
    @last_time = Gosu::milliseconds()
  end

  def update
    delta = Gosu::milliseconds() - @last_time
    @last_time = Gosu::milliseconds()
    @history.map! do |block|
      block[:pos] += SPEED * delta
      block
    end
    @history.reject!{ |block| block[:pos] > WIDTH }
    if @down and not @history.empty?
      @history.last[:width] += @history.last[:pos]
      @history.last[:pos] = 0
    end
  end

  def draw
    @history.each do |block|
      Gosu.draw_rect(block[:pos], 100, block[:width], 30, @color)
    end
  end

  def button_down(id)
    if id == Gosu::KB_SPACE
      start_tone
    else
      super
    end
  end

  def button_up(id)
    if id == Gosu::KB_SPACE
      stop_tone
    else
      super
    end
  end

  def start_tone
    unless @channel and @channel.playing?
      volume = 1
      speed = @frequency * 1.0 / SAMPLE_FREQUENCY
      looping = true
      @channel = @sample.play(volume, speed, looping)
    end
    @down = true
    @history << {width: 0, pos: 0}
  end

  def stop_tone
    if @channel.playing?
      @channel.stop
    end
    @down = false
  end
end

Morse.new.show
