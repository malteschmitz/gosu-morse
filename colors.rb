require 'gosu'

module Colors
  DAH = Gosu::Color.new(255, 255, 128, 128)
  DIT = Gosu::Color.new(255, 255, 255, 128)
  NODE = Gosu::Color.new(255, 144, 144, 255)
  BLACK = Gosu::Color::BLACK
  WHITE = Gosu::Color::WHITE

  def self.mix(c1, c2, p)
    alpha = (1-p) * c1.alpha + p * c2.alpha
    red = (1-p) * c1.red + p * c2.red
    green = (1-p) * c1.green + p * c2.green
    blue = (1-p) * c1.blue + p * c2.blue
    Gosu::Color.new(alpha, red, green, blue)
  end

  def self.darken(c, p)
    self.mix(c, BLACK, p)
  end
end