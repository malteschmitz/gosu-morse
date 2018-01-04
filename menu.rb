require_relative 'colors'

class Menu
  BUTTON_REPEAT_INITIAL = 300 # in ms
  BUTTON_REPEAT = 100 # in ms
  MENU_ITEM_SPACE = 30 # in px

  FREQUENCIES = [
    {f: 880000, name: "a''"},
    {f: 783991, name: "g''"},
    {f: 698456, name: "f''"},
    {f: 659255, name: "e''"},
    {f: 587330, name: "d''"},
    {f: 523251, name: "c''"},
    {f: 493883, name: "h'"},
    {f: 440000, name: "a'"},
    {f: 391995, name: "g'"},
    {f: 349228, name: "f'"},
    {f: 329628, name: "e'"},
    {f: 293665, name: "d'"},
    {f: 261626, name: "c'"},
    {f: 246942, name: "h"},
    {f: 220000, name: "a"}
  ]

  def initialize(morse)
    @morse = morse
    set_frequency(3)
    @menu_font = Gosu::Font.new(20)
    build_widths
    @last_button = {}
  end

  def set_frequency(index)
    @frequency_index = index
    @morse.frequency = FREQUENCIES[index][:f] / 1000.0
  end

  def build_widths
    items = [
      "60 FPS",
      "100 CpM [▼/▲]",
      "2000 px/s [F2/F3]",
      "1000 Hz = a'' [F4/F5]",
      "Iambic Mode B [F6]"
    ]
    @widths = items.map do |item|
      @menu_font.text_width(item)
    end
  end

  def draw
    frequency_text = (FREQUENCIES[@frequency_index][:f] / 1000.0).round
    frequency_text = "#{frequency_text} Hz = #{FREQUENCIES[@frequency_index][:name]}"
    iambic_text = "Iambic Mode "
    if @morse.iambic_mode_b
      iambic_text += "B"
    else
      iambic_text += "A"
    end
    items = [
      "#{Gosu.fps} FPS",
      "#{@morse.cpm} CpM [▼/▲]",
      "#{@morse.speed} px/s [F2/F3]",
      "#{frequency_text} [F4/F5]",
      "#{iambic_text} [F6]"
    ]
    x = (@widths.sum + (items.size - 1) * MENU_ITEM_SPACE)/2
    y = Morse::HEIGHT - 30
    items.each_with_index do |item, i|
      xx = x + @widths[i] - @menu_font.text_width(item)
      @menu_font.draw(item, xx, y, 0, 1.0, 1.0, Colors::MENU)
      x += @widths[i] + MENU_ITEM_SPACE
    end
  end

  def keyboard_action(key)
    if Gosu.button_down?(key)
      if @last_button[key]
        delta = @morse.now - @last_button[key][:time]
        count = @last_button[key][:count] || 0
        if delta > BUTTON_REPEAT_INITIAL or
            (delta > BUTTON_REPEAT and count > 1)
          yield
          @last_button[key] = {time: @morse.now, count: count + 1}
        end
      else
        yield
        @last_button[key] = {time: @morse.now, count: 1}
      end
    else
      @last_button.delete(key)
    end
  end

  def read_keyboard
    keyboard_action(Gosu::KB_DOWN) do
      @morse.cpm -= 5 if @morse.cpm > 10
    end
    keyboard_action(Gosu::KB_UP) do
      @morse.cpm += 5 if @morse.cpm < 100
    end
    keyboard_action(Gosu::KB_F2) do
      @morse.speed -= 200 if @morse.speed > 200
    end
    keyboard_action(Gosu::KB_F3) do
      @morse.speed += 200 if @morse.speed < 2000
    end
    keyboard_action(Gosu::KB_F4) do
      set_frequency(@frequency_index + 1) if @frequency_index < FREQUENCIES.size - 1
    end
    keyboard_action(Gosu::KB_F5) do
      set_frequency(@frequency_index - 1) if @frequency_index > 0
    end
    keyboard_action(Gosu::KB_F6) do
      @morse.iambic_mode_b = !@morse.iambic_mode_b
    end
  end
end