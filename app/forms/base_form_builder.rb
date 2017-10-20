class BaseFormBuilder < ActionView::Helpers::FormBuilder
  alias_method :default_text_field, :text_field
  alias_method :default_text_area, :text_area

  def text_field(attr, options = {})
    field_with_label_and_help(:text_field, attr, options.dup)
  end

  def text_area(attr, options = {})
    field_with_label_and_help(:text_area, attr, options.dup)
  end

  def field_with_label_and_help(field, attr, options = {})
    label = options.delete(:label)
    required = options.delete(:required)
    help = options.delete(:help)

    options[:class] ||= "form-control #{attr.to_s.dasherize}"

    "".tap do |html|
      unless label == false
        html << label(attr, label, class: "#{'required' if required}")
      end
      html << send(:"default_#{field}", attr, options)
      if help
        html << @template.content_tag(:small, help.html_safe, class: 'help-block')
      end
    end.html_safe
  end

  def submit(value = nil, options = nil)
    value, options = nil, value if value.is_a?(Hash)
    value ||= submit_default_value
    @template.button_tag(value, options)
  end

  def country_select(attr, options = {})
    options = { include_blank: true }.merge(options)
    label = options.delete(:label)
    required = options.delete(:required)
    selected = @object.send(attr)
    country_options_html = @template.options_from_collection_for_select(Country.all, :id, :country_name, selected)

    html_options = {
      class: "form-control #{attr.to_s.dasherize}",
      data: { placeholder: options[:placeholder] }
    }

    "".tap do |html|
      unless label == false
        html << label(attr, label, class: "#{'required' if required}")
      end
      html << select(attr, country_options_html, options, html_options)
    end.html_safe
  end
end
