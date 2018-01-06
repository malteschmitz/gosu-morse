require_relative 'colors'

class Tree
  FONT_NAME = "fonts/bold/Ubuntu-B.ttf"

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
    @circle = Gosu::Image.new("circle.png")
    @circle_thick = Gosu::Image.new("circle_thick.png")
    @dit = Gosu::Image.new("dit.png")
    @dit_thick = Gosu::Image.new("dit_thick.png")
    @dah = Gosu::Image.new("dah.png")
    @dah_thick = Gosu::Image.new("dah_thick.png")
    @font = Gosu::Font.new(26, name: FONT_NAME)
    reset
  end

  def draw
    @image.draw(0, Morse::HEIGHT / 2, 0)
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
    redraw
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
    redraw
  end

  def get_code(char)
    DATA[char] || ""
  end

  private

  def redraw
    @image = Gosu.record(Morse::WIDTH, Morse::HEIGHT / 2) do
      draw_tree(@tree, 0, Morse::WIDTH / 2, 0)
    end
  end

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
      circle = @circle_thick
    else
      circle = @circle
    end
    circle.draw xx, yy, 0, 0.5, 0.5, color
    @font.draw_rel(text, x, y, 0, 0.5, 0.5, 1.0, 1.0, color)
  end

  # def draw_line(x1, y1, x2, y2, color, thickness, dashed = false)
  #   angle = Gosu.angle(x1, y1, x2, y2)
  #   distance = Gosu.distance(x1, y1, x2, y2)
  #   if dashed
  #     element_length = 3 * thickness
  #   else
  #     element_length = thickness
  #   end
  #   segment_length = element_length + 1.5 * thickness
  #   @morse.rotate(angle, x1, y1) do
  #     y = y1
  #     (distance / segment_length).to_i.times do
  #       @morse.draw_rect(x1 - thickness / 2.0, y - distance, thickness, element_length, color)
  #       y += segment_length
  #     end
  #   end
  # end

  def draw_line(x1, y1, x2, y2, color, image)
    angle = Gosu.angle(x1, y1, x2, y2) - 90
    distance = Gosu.distance(x1, y1, x2, y2)
    thickness = image.height
    image = image.subimage(0, 0, distance.round, thickness.round)
    image.draw_rot(x1, y1, 0, angle, 0, 0.5, 1, 1, color)
  end

  def sibling_distance(level)
    2 ** (NUMBER_LEVELS - level - 1) * MINIMAL_SIBLING_DISTANCE
  end

  def draw_tree(node, level, x, y)
    if node[:dah]
      if @morse.swap_left_right
        xx = x - sibling_distance(level)
      else
        xx = x + sibling_distance(level)
      end
      yy = y + LEVEL_DISTANCE
      if node[:dah][:active]
        color = Colors::DAH_ACTIVE
        image = @dah_thick
      else
        color = Colors::DAH
        image = @dah
      end
      draw_line(x, y, xx, yy, color, image)
      draw_tree(node[:dah], level + 1, xx, yy)
    end
    if node[:dit]
      if @morse.swap_left_right
        xx = x + sibling_distance(level)
      else
        xx = x - sibling_distance(level)
      end
      yy = y + LEVEL_DISTANCE
      if node[:dit][:active]
        color = Colors::DIT_ACTIVE
        image = @dit_thick
      else
        color = Colors::DIT
        image = @dit
      end
      draw_line(x, y, xx, yy, color, image)
      draw_tree(node[:dit], level + 1, xx, yy)
    end
    draw_node(x, y, node[:symbol] || "", node[:active])
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