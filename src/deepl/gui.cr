require "../ext/crest"
require "gtk4"
require "deepl"
require "easyclip"

TRANSLATOR = DeepL::Translator.new

# Retrieve source and target languages
SOURCE_LANGUAGES = TRANSLATOR.get_source_languages
TARGET_LANGUAGES = TRANSLATOR.get_target_languages
default_target_lang_name = TRANSLATOR.guess_target_language || "EN"
default_target_lang_index = (TARGET_LANGUAGES.index { |lang| lang.language == default_target_lang_name } || 0).to_u32

app = Gtk::Application.new("com.example.translator", Gio::ApplicationFlags::None)

def perform_translation(source_lang_dropdown, target_lang_dropdown, source_text_view, text_right)
  source_text = source_text_view.buffer.text
  return if source_text.empty?
  i = source_lang_dropdown.selected
  source_lang = if i > 0 && i <= SOURCE_LANGUAGES.size
                  SOURCE_LANGUAGES[i - 1].language
                else
                  nil
                end

  target_lang = TARGET_LANGUAGES[target_lang_dropdown.selected].language

  begin
    translated_text = TRANSLATOR.translate_text(
      source_text,
      source_lang: source_lang,
      target_lang: target_lang
    )
    text_right.buffer.text = translated_text[0].text
  rescue ex
    text_right.buffer.text = "Error: #{ex.message}"
  end
end

app.activate_signal.connect do
  Gtk::ApplicationWindow.new(app).tap do |window|
    window.title = "DeepL Translator"
    window.set_default_size(800, 400)

    # Create the main vertical box for layout
    main_box = Gtk::Box.new(:vertical, 10).tap do |b|
      b.margin_top = 10
      b.margin_bottom = 10
      b.margin_start = 10
      b.margin_end = 10
    end

    # Load the CSS into a provider for text styling
    css = <<-CSS
  textview {
    font-size: 20px;
  }
  CSS

    css_provider = Gtk::CssProvider.new
    css_provider.load_from_string(css)

    translate_button = Gtk::Button.new_with_label("Translate")
    source_lang_dropdown = Gtk::DropDown.new_from_strings(
      SOURCE_LANGUAGES.map(&.name).unshift("AUTO")
    )
    source_text_view = Gtk::TextView.new

    left_panel = Gtk::Box.new(:vertical, 10).tap do |lp|
      lp.hexpand = true
      lp.vexpand = true

      source_lang_dropdown.tap do |l|
        l.selected = 0
        l.hexpand = false
        l.halign = :start
        l.set_size_request(180, -1)
      end

      source_text_view.wrap_mode = :word

      style_context_left = source_text_view.style_context
      style_context_left.add_provider(css_provider, Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32)

      scroll_left = Gtk::ScrolledWindow.new.tap do |s|
        s.child = source_text_view
        s.hexpand = true
        s.vexpand = true
      end

      lp.append(source_lang_dropdown)
      lp.append(scroll_left)
      lp.append(translate_button)
    end

    target_lang_dropdown = Gtk::DropDown.new_from_strings(
      TARGET_LANGUAGES.map(&.name)
    )
    copy_button = Gtk::Button.new_with_label("Copy")
    target_text_view = Gtk::TextView.new

    right_panel = Gtk::Box.new(:vertical, 10).tap do |rp|
      rp.hexpand = true
      rp.vexpand = true

      target_lang_dropdown.tap do |l|
        l.selected = default_target_lang_index
        l.hexpand = false
        l.halign = :start
        l.set_size_request(180, -1)
      end

      target_text_view.tap do |t|
        t.wrap_mode = :word
        t.editable = false
      end

      style_context_right = target_text_view.style_context
      style_context_right.add_provider(css_provider, Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32)

      scroll_right = Gtk::ScrolledWindow.new.tap do |s|
        s.child = target_text_view
        s.hexpand = true
        s.vexpand = true
      end

      rp.append(target_lang_dropdown)
      rp.append(scroll_right)
      rp.append(copy_button)
    end

    # Horizontal box for the two panels
    text_box = Gtk::Box.new(:horizontal, 10)
    text_box.append(left_panel)
    text_box.append(right_panel)

    main_box.append(text_box)
    window.child = main_box
    window.present

    translate_button.clicked_signal.connect do
      perform_translation(source_lang_dropdown, target_lang_dropdown, source_text_view, target_text_view)
    end

    copy_button.clicked_signal.connect do
      target_text = target_text_view.buffer.text
      EasyClip.copy(target_text)
    end
  end
end

# Run the application
exit(app.run)
