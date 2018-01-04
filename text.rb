class Text
  FONT = 'fonts/mono/UbuntuMono-R.ttf'
  FONT_HEIGHT = 60
  MARGIN = 40
  POSITION = 20
  LINE_WIDTH = 60
  NUMBER_LINES = 5
  CURSOR_CHAR = "⎸"
  CURSOR_BLINK_RATE = 600

  attr_reader :text

  def initialize(morse)
    @morse = morse
    self.text = "12345678901234567890123456789012345678901234567890123456789012345\nZeile 2 2 2 2 2 2 2 2\nZeile 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3\nZeile 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4\nZeile 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5"
    #self.text = "Hallo 1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890 Hallo Welt, hier steht ganz viel Text. Mal sehen, wie das dann aussieht..."
  end

  def text=(new_text)
    new_text = wrap(new_text, LINE_WIDTH)
    if new_text.size > NUMBER_LINES
      new_text = new_text[-NUMBER_LINES..-1]
    end
    new_text = new_text.join("\n")
    @text = new_text
    width = Morse::WIDTH - 2 * MARGIN
    @image_on = Gosu::Image.from_text(@text + CURSOR_CHAR, FONT_HEIGHT, font: FONT, width: width)
    @image_off = Gosu::Image.from_text(@text, FONT_HEIGHT, font: FONT, width: width)
  end

  def draw
    if @morse.now % (CURSOR_BLINK_RATE * 2) >= CURSOR_BLINK_RATE
      image = @image_on
    else
      image = @image_off
    end
    image.draw(MARGIN, POSITION, 0, 1.0, 1.0, Colors::TEXT)
  end

  private

  def wrap(s, width)
    s.split(/\n/, -1).map{ |l| wrap_line(l, width) }.flatten
  end

  def wrap_line(s, width)
    lines = []
    line = ""
    s.split(/ /, -1).each do |word|
      if !line.empty? and line.size + word.size >= width
        lines << line
        line = ""
      end
      if line.empty?
        while word.size > width
          lines << word[0..width-1]
          word = word[width..-1]
        end
        line = word if word
      else
        line << " " << word
      end
    end
    lines << line if line
    lines
  end
end