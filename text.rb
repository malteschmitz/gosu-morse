class Text
  FONT_NAME = "fonts/mono/UbuntuMono-R.ttf"
  FONT_HEIGHT = 60
  LINE_HEIGHT = 60
  MARGIN = 40
  POSITION = 10
  LINE_WIDTH = 60
  NUMBER_LINES = 5
  CURSOR_CHAR = "⎸"
  CURSOR_BLINK_RATE = 600

  attr_reader :highlighting
  attr_reader :preview

  def initialize(morse)
    @morse = morse
    @font = Gosu::Font.new(FONT_HEIGHT, name: FONT_NAME)
    @text = ""
    @preview = ""
    reset
  end

  def reset
    self.text = "\n" * NUMBER_LINES
    self.preview = ""
  end

  def text
    @lines.join("\n")
  end

  def text=(new_text)
    @lines = wrap(new_text, LINE_WIDTH)
    if @lines.size > NUMBER_LINES
      @lines = @lines[-NUMBER_LINES..-1]
    end
    render
  end

  def highlighting=(val)
    @highlighting = val
    render
  end

  def preview=(val)
    @preview = val
    render
  end

  def draw
    if @morse.now % (CURSOR_BLINK_RATE * 2) >= CURSOR_BLINK_RATE
      @image_cursor.draw(MARGIN, POSITION, 0)
    end
    @image_text.draw(MARGIN, POSITION, 0)
    @image_highlight.draw(MARGIN, POSITION, 0)
    @image_preview.draw(MARGIN, POSITION, 0)
  end

  private

  def render
    last = @lines[-1]
    y_last = (NUMBER_LINES - 1) * LINE_HEIGHT
    if @highlighting and last.size > 1 and last[-1] == " "
      highlight_chars = 2
    elsif @highlighting and last.size > 0
      highlight_chars = 1
    else
      highlight_chars = 0
    end
    @image_cursor = Gosu.record(Morse::WIDTH, 500) do
      cursor = " " * last.size + CURSOR_CHAR
      @font.draw(cursor, 0, y_last, 0, 1.0, 1.0, Colors::CURSOR)
    end
    @image_text = Gosu.record(Morse::WIDTH, 500) do
      @lines.each_with_index do |line, index|
        y = index * LINE_HEIGHT
        color = Colors::darken(Colors::WHITE, (NUMBER_LINES - 1 - index) * 0.0625 + 0.25)
        line = line[0..-highlight_chars-1] if index == NUMBER_LINES - 1
        @font.draw(line, 0, y, 0, 1.0, 1.0, color)
      end
    end
    @image_highlight = Gosu.record(Morse::WIDTH, 500) do
      if highlight_chars > 0
        highlight = " " * (last.size - highlight_chars) + last[-highlight_chars..-1]
        @font.draw(highlight, 0, y_last, 0, 1.0, 1.0, Colors::TEXT_HIGHLIGHT)
      end
    end
    @image_preview = Gosu.record(Morse::WIDTH, 500) do
      preview = " " * last.size + @preview
      @font.draw(preview, 0, y_last, 0, 1.0, 1.0, Colors::TEXT_PREVIEW)
    end
  end

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