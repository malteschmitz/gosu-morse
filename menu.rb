require_relative 'colors'

class Menu
  BUTTON_REPEAT_INITIAL = 300 # in ms
  BUTTON_REPEAT = 100 # in ms
  MENU_ITEM_SPACE = 30 # in px
  CPM_STEP = 5
  CPM_MIN = 10
  CPM_MAX = 100
  CHECKBOX_CHAR = "▢"
  CHECKBOX_CHECKED_CHAR = "✔"

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
      "Key [RET]",
      "·/− [F7]",
      "100 CpM [▼/▲]",
      CHECKBOX_CHAR + " auto [F2]",
      "2000 px/s [F2/F2]",
      "1000 Hz = a'' [F2/F2]",
      "Iambic B [F2]",
      "Fullscreen [F11]",
      "Clear [ESC]",
      "Resume [F12]"
    ]
    @widths = items.map do |item|
      @menu_font.text_width(item)
    end
  end

  def draw
    frequency_text = (FREQUENCIES[@frequency_index][:f] / 1000.0).round
    frequency_text = "#{frequency_text} Hz = #{FREQUENCIES[@frequency_index][:name]}"
    iambic_text = "Iambic "
    if @morse.iambic_mode_b
      iambic_text += "B"
    else
      iambic_text += "A"
    end
    if @morse.auto_cpm
      auto_cpm_text = CHECKBOX_CHECKED_CHAR
    else
      auto_cpm_text = CHECKBOX_CHAR
    end
    if @morse.swap_left_right
      swap_left_right_text = "−/•"
    else
      swap_left_right_text = "•/−"
    end
    if @morse.pause
      pause_text = "Resume"
    else
      pause_text = "Pause"
    end
    items = [
      "#{Gosu.fps} FPS",
      "Key [RET]",
      "#{swap_left_right_text} [F7]",
      "#{@morse.cpm} CpM [▼/▲]",
      "#{auto_cpm_text} auto [F8]",
      "#{@morse.speed} px/s [F2/F3]",
      "#{frequency_text} [F4/F5]",
      "#{iambic_text} [F6]",
      "Fullscreen [F11]",
      "Clear [ESC]",
      "#{pause_text} [F12]"
    ]
    x = (Morse::WIDTH - @widths.sum - (items.size - 1) * MENU_ITEM_SPACE) / 2.0
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
      @morse.auto_cpm = false
      @morse.cpm -= CPM_STEP if @morse.cpm > CPM_MIN
    end
    keyboard_action(Gosu::KB_UP) do
      @morse.auto_cpm = false
      @morse.cpm += CPM_STEP if @morse.cpm < CPM_MAX
    end
    keyboard_action(Gosu::KB_F2) do
      if @morse.speed > 400
        @morse.speed -= 100
      elsif @morse.speed > 50
        @morse.speed -= 50
      elsif @morse.speed > 10
        @morse.speed -= 10
      end
    end
    keyboard_action(Gosu::KB_F3) do
      if @morse.speed < 50
        @morse.speed += 10
      elsif @morse.speed < 400
        @morse.speed += 50
      elsif @morse.speed < 1000
        @morse.speed += 100
      end
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
    keyboard_action(Gosu::KB_F7) do
      @morse.swap_left_right = !@morse.swap_left_right
    end
    keyboard_action(Gosu::KB_F8) do
      @morse.auto_cpm = !@morse.auto_cpm
    end
    keyboard_action(Gosu::KB_F11) do
      @morse.fullscreen = !@morse.fullscreen?
    end
    keyboard_action(Gosu::KB_F12) do
      @morse.pause = !@morse.pause
    end
  end
end