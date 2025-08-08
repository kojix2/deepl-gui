require "../ext/crest"
require "gtk4"
require "deepl"
require "easyclip"

class APP
  TRANSLATOR       = DeepL::Translator.new
  SOURCE_LANGUAGES = TRANSLATOR.get_source_languages
  TARGET_LANGUAGES = TRANSLATOR.get_target_languages

  @app : Gtk::Application
  @source_lang_dropdown : Gtk::DropDown?
  @source_text_view : Gtk::TextView?
  @target_lang_dropdown : Gtk::DropDown?
  @target_text_view : Gtk::TextView?

  def source_lang_dropdown : Gtk::DropDown
    @source_lang_dropdown.not_nil!
  end

  def source_text_view : Gtk::TextView
    @source_text_view.not_nil!
  end

  def target_lang_dropdown : Gtk::DropDown
    @target_lang_dropdown.not_nil!
  end

  def target_text_view : Gtk::TextView
    @target_text_view.not_nil!
  end

  def self.run
    new.run
  end

  def initialize
    @app = Gtk::Application.new("com.example.translator", Gio::ApplicationFlags::None)
    @app.activate_signal.connect { activate }
  end

  def run
    @app.run
  end

  def default_target_lang_index
    default_target_lang_name = TRANSLATOR.guess_target_language || "EN"
    (TARGET_LANGUAGES.index { |lang| lang.language == default_target_lang_name } || 0).to_u32
  end

  def css
    <<-CSS
      textview {
        font-size: 20px;
      }
    CSS
  end

  def activate
    Gtk::ApplicationWindow.new(@app).tap { |window|
      window.title = "DeepL Translator"
      window.set_default_size(800, 400)

      window.child = Gtk::Box.new(:vertical, 10).tap { |main_box|
        main_box.margin_top = 10
        main_box.margin_bottom = 10
        main_box.margin_start = 10
        main_box.margin_end = 10

        main_box.append(
          Gtk::Box.new(:horizontal, 10).tap do |text_box|
            css_provider = Gtk::CssProvider.new
            css_provider.load_from_string(css)

            text_box.append Gtk::Box.new(:vertical, 10).tap { |left_box|
              left_box.hexpand = true
              left_box.vexpand = true

              @source_lang_dropdown = Gtk::DropDown.new_from_strings(SOURCE_LANGUAGES.map(&.name).unshift("AUTO"))
              left_box.append source_lang_dropdown.tap { |l|
                l.selected = 0
                l.hexpand = false
                l.halign = :start
                l.set_size_request(180, -1)
              }

              left_box.append Gtk::ScrolledWindow.new.tap { |s|
                s.hexpand = true
                s.vexpand = true
                @source_text_view = Gtk::TextView.new
                s.child = source_text_view.tap { |t|
                  t.wrap_mode = :word
                  Gtk::StyleContext.add_provider_for_display(
                    t.display,
                    css_provider,
                    Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32
                  )
                }
              }

              left_box.append Gtk::Button.new_with_label("Translate").tap { |translate_button|
                translate_button.clicked_signal.connect { perform_translation }
              }
            }

            text_box.append Gtk::Box.new(:vertical, 10).tap { |rp|
              rp.hexpand = true
              rp.vexpand = true

              rp.append Gtk::Box.new(:horizontal, 0).tap { |tlb|
                tlb.hexpand = true

                @target_lang_dropdown = Gtk::DropDown.new_from_strings(TARGET_LANGUAGES.map(&.name))
                tlb.append target_lang_dropdown.tap { |l|
                  l.selected = default_target_lang_index
                  l.hexpand = false
                  l.halign = :start
                  l.set_size_request(180, -1)
                }

                home_target_lang_button = Gtk::Button.new_with_label("🏠").tap { |b|
                  b.clicked_signal.connect { target_lang_dropdown.selected = default_target_lang_index }
                }
                tlb.append home_target_lang_button
              }

              rp.append Gtk::ScrolledWindow.new.tap { |s|
                s.hexpand = true
                s.vexpand = true
                @target_text_view = Gtk::TextView.new
                s.child = target_text_view.tap { |t|
                  t.wrap_mode = :word
                  t.editable = false
                  Gtk::StyleContext.add_provider_for_display(
                    t.display,
                    css_provider,
                    Gtk::STYLE_PROVIDER_PRIORITY_USER.to_u32
                  )
                }
              }

              rp.append Gtk::Button.new_with_label("Copy").tap { |copy_button|
                copy_button.clicked_signal.connect do
                  target_text = target_text_view.buffer.text
                  EasyClip.copy(target_text)
                end
              }
            }
          end
        )
      }

      window.present
    }
  end

  def source_text : String
    source_text_view.buffer.text
  end

  def source_language_selected : String?
    idx = source_lang_dropdown.selected
    if idx > 0 && idx <= SOURCE_LANGUAGES.size
      SOURCE_LANGUAGES[idx - 1].language
    else
      nil
    end
  end

  def target_language_selected : String
    idx = target_lang_dropdown.selected
    TARGET_LANGUAGES[idx].language
  end

  def perform_translation
    return if source_text.empty?

    source_lang = source_language_selected
    target_lang = target_language_selected

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
end

APP.run
