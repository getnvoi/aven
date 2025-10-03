# frozen_string_literal: true

class Sqema::Ui::FormBuilder < ActionView::Helpers::FormBuilder
  class BaseComponent < Sqema::ApplicationViewComponent
    INPUT_BASE_CLASSES = %w[
      block
      w-full
      rounded-md
      bg-white
      px-3
      py-2
      text-sm
      text-gray-900
      placeholder:text-gray-400
      outline-none
      border
      border-gray-300
      focus:border-indigo-500
      focus:ring-1
      focus:ring-indigo-500
      shadow-sm
    ].freeze

    option(:id, optional: true)
    option(:name)
    option(:value, optional: true)
    option(:disabled, default: proc { false })
    option(:label, optional: true)
    option(:type, optional: true)
    option(:helper_text, optional: true)
    option(:error_text, optional: true)
    option(:placeholder, optional: true)
    option(:required, default: proc { false })
    option(:data, default: proc { {} })
  end

  def field(field_type, name, options = {}, &block)
    klass = "Ui::Input#{field_type.to_s.classify}::Component".constantize
    resolved_name = resolve_name(name)
    error_text = @object&.errors&.[](name)&.first

    value = options[:value] || @object&.send(name)

    merged_options = options.merge(
      id: options[:id] || "#{@object_name}_#{name}".parameterize(separator: "_"),
      name: resolved_name,
      error_text:,
      value:
    )

    @template.render(klass.new(**merged_options), &block)
  end

  def text_field(name, options = {})
    field(:text, name, options)
  end

  def password_field(name, options = {})
    field(:password, name, options.merge(type: "password"))
  end

  def select_field(name, options = {}, &block)
    field(:select, name, options, &block)
  end

  private

    def resolve_name(name)
      @object_name ? "#{@object_name}[#{name}]" : name
    end
end
