require 'gosu'

module Colors
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

  BLACK = Gosu::Color::BLACK
  WHITE = Gosu::Color::WHITE
  DAH_ACTIVE = Gosu::Color.new(255, 255, 128, 128)
  DIT_ACTIVE = Gosu::Color.new(255, 255, 255, 128)
  NODE_ACTIVE = Gosu::Color.new(255, 144, 144, 255)
  MENU = darken(WHITE, 0.25)
  TEXT_HIGHLIGHT = NODE_ACTIVE
  CURSOR = WHITE
  DAH = MENU
  DIT = MENU
  NODE = MENU
end