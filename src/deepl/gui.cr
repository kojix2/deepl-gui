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

def perform_translation(source_lang_dropdown, target_lang_dropdown, source_text_view, target_text_view)
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
    target_text_view.buffer.text = translated_text[0].text
  rescue ex
    target_text_view.buffer.text = "Error: #{ex.message}"
  end
end

app.activate_signal.connect do
  Gtk::ApplicationWindow.new(app).tap do |window|
    window.title = "DeepL Translator"
    window.set_default_size(800, 400)
    window.child = Gtk::Box.new(:vertical, 10).tap do |main_box|
      main_box.margin_top = 10
      main_box.margin_bottom = 10
      main_box.margin_start = 10
      main_box.margin_end = 10

      main_box.append(
        Gtk::Box.new(:horizontal, 10).tap do |text_box|
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

          text_box.append(
            Gtk::Box.new(:vertical, 10).tap do |lp|
              lp.hexpand = true
              lp.vexpand = true

              lp.append(
                source_lang_dropdown.tap do |l|
                  l.selected = 0
                  l.hexpand = false
                  l.halign = :start
                  l.set_size_request(180, -1)
                end
              )

              lp.append(
                Gtk::ScrolledWindow.new.tap do |s|
                  s.hexpand = true
                  s.vexpand = true
                  s.child = source_text_view.tap do |t|
                    t.wrap_mode = :word
                    t.style_context
                      .add_provider(css_provider, Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32)
                  end
                end
              )

              lp.append(translate_button)
            end
          )

          target_lang_dropdown = Gtk::DropDown.new_from_strings(
            TARGET_LANGUAGES.map(&.name)
          )
          target_text_view = Gtk::TextView.new

          text_box.append(
            Gtk::Box.new(:vertical, 10).tap do |rp|
              rp.hexpand = true
              rp.vexpand = true

              rp.append(
                target_lang_dropdown.tap do |l|
                  l.selected = default_target_lang_index
                  l.hexpand = false
                  l.halign = :start
                  l.set_size_request(180, -1)
                end
              )

              rp.append(
                Gtk::ScrolledWindow.new.tap do |s|
                  s.hexpand = true
                  s.vexpand = true
                  s.child = target_text_view.tap do |t|
                    t.wrap_mode = :word
                    t.editable = false
                    t.style_context
                      .add_provider(css_provider, Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32)
                  end
                end
              )

              rp.append(
                Gtk::Button.new_with_label("Copy").tap do |copy_button|
                  copy_button.clicked_signal.connect do
                    target_text = target_text_view.buffer.text
                    EasyClip.copy(target_text)
                  end
                end
              )
            end
          )

          translate_button.clicked_signal.connect do
            perform_translation(source_lang_dropdown, target_lang_dropdown, source_text_view, target_text_view)
          end
        end
      )
    end

    window.present
  end
end

# Run the application
exit(app.run)
