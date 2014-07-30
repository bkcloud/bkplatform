module ApplicationHelper
  def app_url(app)
    if request.subdomain.present? || request.port == 80
      "http://#{app.name}.#{request.domain}#{request.port == 80 ? "" : ":#{request.port}"}/#{I18n.locale}"
    else
      "http://#{request.host}#{request.port == 80 ? "" : ":#{request.port}"}/#{I18n.locale}/#{app.path}"
    end
  end
  def lang_switcher
    content_tag(:ul, class: 'lang-switcher clearfix', style: 'list-style: none; margin-left: 0;') do
      I18n.available_locales.each do |loc|
        locale_param = request.path == root_path ? root_path(locale: loc) : params.merge(locale: loc)
        concat content_tag(:li, (link_to language_name(loc.to_s), locale_param), class: (I18n.locale == loc ? "active" : ""))
      end
    end
  end

  def language_name(arg)
    if arg == "en"
      "English"
    elsif arg == "vi"
      "Tiếng Việt"
    else
      "Undefined"
    end
  end

end
