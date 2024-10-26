require "gtk4"
require "deepl"

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

  # Set up the language selection dropdowns
  lang_box_left = Gtk::DropDown.new_from_strings(source_languages.map(&.name))
  lang_box_right = Gtk::DropDown.new_from_strings(target_languages.map(&.name))

  lang_box_left.selected = 0 # Select the first language by default
  lang_box_right.selected = 0

  # Create the Translate button
  translate_button = Gtk::Button.new_with_label("Translate")

  # Create a horizontal box for language selection and button
  lang_and_button_box = Gtk::Box.new(:horizontal, 10)
  lang_and_button_box.append(lang_box_left)
  lang_and_button_box.append(lang_box_right)
  lang_and_button_box.append(translate_button)

  # Create text views and make them scrollable
  text_left = Gtk::TextView.new
  text_right = Gtk::TextView.new
  text_right.editable = false # Disable editing for the translated text view

  scroll_left = Gtk::ScrolledWindow.new
  scroll_left.child = text_left
  scroll_left.hexpand = true
  scroll_left.vexpand = true

  scroll_right = Gtk::ScrolledWindow.new
  scroll_right.child = text_right
  scroll_right.hexpand = true
  scroll_right.vexpand = true

  # Create a horizontal box for the text areas
  text_box = Gtk::Box.new(:horizontal, 10)
  text_box.append(scroll_left)
  text_box.append(scroll_right)

  # Add the language box and text areas to the main box
  main_box.append(lang_and_button_box)
  main_box.append(text_box)

  # Connect the click event to the Translate button
  translate_button.clicked_signal.connect do
    # Get the input text and selected languages
    source_text = text_left.buffer.text
    source_lang = source_languages[lang_box_left.selected].language
    target_lang = target_languages[lang_box_right.selected].language

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

  # Set the main box as the child of the window and display it
  window.child = main_box
  window.present
end

# Run the application
exit(app.run)
