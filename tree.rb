require 'texplay'

class Tree
  DATA = {
    "A" => ".-",
    "B" => "-...",
    "C" => "-.-.",
    "D" => "-..",
    "E" => ".",
    "F" => "..-.",
    "G" => "--.",
    "H" => "....",
    "I" => "..",
    "J" => ".---",
    "K" => "-.-",
    "L" => ".-..",
    "M" => "--",
    "N" => "-.",
    "O" => "---",
    "P" => ".--.",
    "Q" => "--.-",
    "R" => ".-.",
    "S" => "...",
    "T" => "-",
    "U" => "..-",
    "V" => "...-",
    "W" => ".--",
    "X" => "-..-",
    "Y" => "-.--",
    "Z" => "--..",
    "1" => ".----",
    "2" => "..---",
    "3" => "...--",
    "4" => "....-",
    "5" => ".....",
    "6" => "-....",
    "7" => "--...",
    "8" => "---..",
    "9" => "----.",
    "0" => "-----"
  }
  LEVEL_DISTANCE = 70
  LINE_THICKNESS = 2
  NUMBER_LEVELS = 5
  MINIMAL_SIBLING_DISTANCE = 23.5

  def initialize(morse)
    @morse = morse
    build_tree
  end

  def draw
    draw_tree(@tree, 0, Morse::WIDTH / 2, Morse::HEIGHT / 2)
  end

  private

  def draw_line(x1, y1, x2, y2, color, thickness)
    angle = Gosu.angle(x1, y1, x2, y2)
    distance = Gosu.distance(x1, y1, x2, y2)
    @morse.rotate(angle, x1, y1) do
      @morse.draw_rect(x1 - thickness / 2.0, y1 - distance, thickness, distance, color)
    end
  end

  def sibling_distance(level)
    2 ** (NUMBER_LEVELS - level - 1) * MINIMAL_SIBLING_DISTANCE
  end

  def draw_tree(node, level, x, y)
    if node[:dah]
      xx = x + sibling_distance(level)
      yy = y + LEVEL_DISTANCE
      draw_line(x, y, xx, yy, Morse::DAH_COLOR, LINE_THICKNESS)
      draw_tree(node[:dah], level + 1, xx, yy)
    end
    if node[:dit]
      xx = x - sibling_distance(level)
      yy = y + LEVEL_DISTANCE
      draw_line(x, y, xx, yy, Morse::DIT_COLOR, LINE_THICKNESS)
      draw_tree(node[:dit], level + 1, xx, yy)
    end
  end

  def add_symbol(node, symbol, code)
    if code == ""
      node[:symbol] = symbol
    elsif code[0] == "."
      node[:dit] = {} unless node[:dit]
      add_symbol(node[:dit], symbol, code[1..-1])
    elsif code[0] == "-"
      node[:dah] = {} unless node[:dah]
      add_symbol(node[:dah], symbol, code[1..-1])
    end
  end

  def build_tree
    @tree = {}
    DATA.each do |symbol, code|
      add_symbol(@tree, symbol, code)
    end
  end
end