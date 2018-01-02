require 'gosu'
require 'serialport'

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
    @mutex = Mutex.new
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
    @mutex.synchronize do
      unless @channel and @channel.playing?
        volume = 1
        speed = @frequency * 1.0 / SAMPLE_FREQUENCY
        looping = true
        @channel = @sample.play(volume, speed, looping)
      end
      @down = true
      @history << {width: 0, pos: 0}
    end
  end

  def stop_tone
    @mutex.synchronize do
      if @channel and @channel.playing?
        @channel.stop
      end
      @down = false
    end
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
  port = SerialPort.new(SERIAL_PORT, SERIAL_BAUD)
  loop do
    c = port.getbyte
    case c
    when LEFT_COMMAND + UP_COMMAND
      $morse.stop_tone
    when LEFT_COMMAND + DOWN_COMMAND
      $morse.start_tone
    end
  end
end

$morse.show
serialThread.exit
