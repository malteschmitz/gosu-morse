require_relative 'colors'

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
  LEVEL_DISTANCE = 75
  LINE_THICKNESS = 3
  LINE_THICKNESS_ACTIVE = 5
  NUMBER_LEVELS = 5
  MINIMAL_SIBLING_DISTANCE = 23.5

  def initialize(morse)
    @morse = morse
    build_tree
    @circle = Gosu::Image.new("circle.png", :tileable => true)
    @circle_active = Gosu::Image.new("circle_thick.png", :tileable => true)
    @font = Gosu::Font.new(26, name: "fonts/bold/Ubuntu-B.ttf")
    reset
  end

  def draw
    draw_tree(@tree, 0, Morse::WIDTH / 2, Morse::HEIGHT / 2)
  end

  def symbol
    if @current_node
      @current_node[:symbol]
    else
      nil
    end
  end

  def reset
    enable_tree
  end

  def go(code)
    return unless @current_node
    if code == "." and @current_node[:dit]
      @current_node = @current_node[:dit]
    elsif code == "-" and @current_node[:dah]
      @current_node = @current_node[:dah]
    else
      disable_tree
    end
    @current_node[:active] = true if @current_node
  end

  def get_code(char)
    DATA[char] || ""
  end

  private

  def disable_tree
    disable_node(@tree)
    @current_node = nil
  end

  def enable_tree
    disable_node(@tree)
    @current_node = @tree
    @current_node[:active] = true
  end

  def disable_node(node)
    node.delete(:active)
    disable_node(node[:dah]) if node[:dah]
    disable_node(node[:dit]) if node[:dit]
  end

  def draw_node(x, y, text, active = false)
    color = active ? Colors::NODE_ACTIVE : Colors::NODE
    offset = @circle.width / 4
    xx = x - offset
    yy = y - offset
    if active
      circle = @circle_active
    else
      circle = @circle
    end
    circle.draw xx, yy, 0, 0.5, 0.5, color
    @font.draw_rel(text, x, y, 0, 0.5, 0.5, 1.0, 1.0, color)
  end

  def draw_line(x1, y1, x2, y2, color, thickness, dashed = false)
    angle = Gosu.angle(x1, y1, x2, y2)
    distance = Gosu.distance(x1, y1, x2, y2)
    if dashed
      element_length = 3 * thickness
    else
      element_length = thickness
    end
    segment_length = element_length + 1.5 * thickness
    @morse.rotate(angle, x1, y1) do
      y = y1
      (distance / segment_length).to_i.times do
        @morse.draw_rect(x1 - thickness / 2.0, y - distance, thickness, element_length, color)
        y += segment_length
      end
    end
  end

  def sibling_distance(level)
    2 ** (NUMBER_LEVELS - level - 1) * MINIMAL_SIBLING_DISTANCE
  end

  def draw_tree(node, level, x, y)
    if node[:dah]
      xx = x + sibling_distance(level)
      yy = y + LEVEL_DISTANCE
      if node[:dah][:active]
        color = Colors::DAH_ACTIVE
        thickness = LINE_THICKNESS_ACTIVE
      else
        color = Colors::DAH
        thickness = LINE_THICKNESS
      end
      draw_line(x, y, xx, yy, color, thickness, true)
      draw_tree(node[:dah], level + 1, xx, yy)
    end
    if node[:dit]
      xx = x - sibling_distance(level)
      yy = y + LEVEL_DISTANCE
      if node[:dit][:active]
        color = Colors::DIT_ACTIVE
        thickness = LINE_THICKNESS_ACTIVE
      else
        color = Colors::DIT
        thickness = LINE_THICKNESS
      end
      draw_line(x, y, xx, yy, color, thickness)
      draw_tree(node[:dit], level + 1, xx, yy)
    end
    draw_node(x,y, node[:symbol] || "", node[:active])
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