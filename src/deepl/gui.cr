require "../ext/crest"
require "gtk4"
require "deepl"
require "easyclip"

translator = DeepL::Translator.new

# Retrieve source and target languages
source_languages = translator.get_source_languages
target_languages = translator.get_target_languages

app = Gtk::Application.new("com.example.translator", Gio::ApplicationFlags::None)

app.activate_signal.connect do
  window = Gtk::ApplicationWindow.new(app)
  window.title = "DeepL Translator"
  window.set_default_size(800, 400)

  # Create the main vertical box for layout
  main_box = Gtk::Box.new(:vertical, 10)
  main_box.margin_top = 10
  main_box.margin_bottom = 10
  main_box.margin_start = 10
  main_box.margin_end = 10

  # Load the CSS into a provider for text styling
  css = <<-CSS
  textview {
    font-size: 20px;
  }
  CSS

  css_provider = Gtk::CssProvider.new
  css_provider.load_from_string(css)

  # Left panel with source language dropdown, text input, and button
  left_panel = Gtk::Box.new(:vertical, 10)

  # Configure the source language dropdown
  lang_box_left = Gtk::DropDown.new_from_strings(
    source_languages.map(&.name).unshift("AUTO")
  )
  lang_box_left.selected = 0
  lang_box_left.hexpand = false
  lang_box_left.halign = :start
  lang_box_left.set_size_request(150, -1)

  text_left = Gtk::TextView.new
  text_left.wrap_mode = :word
  style_context_left = text_left.style_context
  style_context_left.add_provider(css_provider, Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32)

  scroll_left = Gtk::ScrolledWindow.new
  scroll_left.child = text_left
  scroll_left.hexpand = true
  scroll_left.vexpand = true

  translate_button = Gtk::Button.new_with_label("Translate")

  left_panel.append(lang_box_left)
  left_panel.append(scroll_left)
  left_panel.append(translate_button)

  # Right panel with target language dropdown and text output
  right_panel = Gtk::Box.new(:vertical, 10)

  # Configure the target language dropdown
  lang_box_right = Gtk::DropDown.new_from_strings(
    target_languages.map(&.name).unshift("AUTO")
  )
  lang_box_right.selected = 0
  lang_box_right.hexpand = false
  lang_box_right.halign = :start
  lang_box_right.set_size_request(150, -1)

  # Copy button
  copy_button = Gtk::Button.new_with_label("Copy")

  text_right = Gtk::TextView.new
  text_right.editable = false
  text_right.wrap_mode = :word
  style_context_right = text_right.style_context
  style_context_right.add_provider(css_provider, Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32)

  scroll_right = Gtk::ScrolledWindow.new
  scroll_right.child = text_right
  scroll_right.hexpand = true
  scroll_right.vexpand = true

  right_panel.append(lang_box_right)
  right_panel.append(scroll_right)
  right_panel.append(copy_button)

  # Horizontal box for the two panels
  text_box = Gtk::Box.new(:horizontal, 10)
  text_box.append(left_panel)
  text_box.append(right_panel)

  main_box.append(text_box)
  window.child = main_box
  window.present

  # Connect the Translate button click event
  translate_button.clicked_signal.connect do
    source_text = text_left.buffer.text
    i = lang_box_left.selected
    source_lang = \
       if i > 0 && i <= source_languages.size
         source_languages[i - 1].language
       else
         nil
       end

    i = lang_box_right.selected
    target_lang = \
       if i > 0 && i <= target_languages.size
         target_languages[i - 1].language
       else
         translator.guess_target_language
       end

    # Perform translation using the DeepL API
    begin
      translated_text = translator.translate_text(
        source_text,
        source_lang: source_lang,
        target_lang: target_lang
      )
      text_right.buffer.text = translated_text[0].text
    rescue ex
      text_right.buffer.text = "Error: #{ex.message}"
    end
  end

  copy_button.clicked_signal.connect do
    target_text = text_right.buffer.text
    EasyClip.copy(target_text)
  end
end

# Run the application
exit(app.run)
