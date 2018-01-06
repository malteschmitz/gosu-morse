module ColorHelper
  def self.to_blob(color)
    color.red.chr + color.green.chr + color.blue.chr + color.alpha.chr
  end
end

class Circle
  attr_reader :columns, :rows
  
  def initialize(radius, thickness, color = Gosu::Color::WHITE, fill_color = Gosu::Color::BLACK, background_color = Gosu::Color::NONE)
    outer_radius = (radius + thickness / 2).round
    inner_radius = (radius - thickness / 2).round
    fill_color = ColorHelper::to_blob(fill_color)
    color = ColorHelper::to_blob(color)
    background_color = ColorHelper::to_blob(background_color)
    @columns = @rows = outer_radius * 2
    lower_half = (0...outer_radius).map do |y|
      outer_x = Math.sqrt(outer_radius**2 - y**2).round
      if y < inner_radius
        inner_x = Math.sqrt(inner_radius**2 - y**2).round
      else
        inner_x = 0
      end
      right_half = "F" * inner_x
      right_half += "C" * (outer_x - inner_x)
      right_half += "B" * (outer_radius - outer_x)
      "#{right_half.reverse}#{right_half}"
    end.join
    @blob = lower_half.reverse + lower_half
    @blob.gsub!(/[FCB]/, {"F" => fill_color, "C" => color, "B" => background_color})
  end
  
  def to_blob
    @blob
  end
end

class Line
  attr_reader :columns, :rows

  def initialize(length, thickness, dot_ratio = 1, space_ratio = 1.5, color = Gosu::Color::WHITE, space_color = Gosu::Color::NONE)
    color = ColorHelper::to_blob(color)
    space_color = ColorHelper::to_blob(space_color)
    dot_length = (dot_ratio * thickness).round
    space_length = (space_ratio * thickness).round
    segment_length = dot_length + space_length
    line = color * dot_length
    line += space_color * space_length
    line *= (length / segment_length).to_i + 1
    line = line[0..length*4-1]
    @blob = line * thickness
    @columns = length
    @rows = thickness
  end

  def to_blob
    @blob
  end
end
