module Sqema::Ui::InputSelect
  class Component < Sqema::Ui::FormBuilder::BaseComponent
    option(:prompt, optional: true)
    option(:options, default: proc { [] })
    option(:collection, optional: true)
    option(:value_method, optional: true)
    option(:label_method, optional: true)

    renders_many :select_options, "OptionComponent"

    class OptionComponent < ApplicationViewComponent
      option(:value)
      option(:label)
      option(:selected, default: proc { false })
      option(:disabled, default: proc { false })

      erb_template <<~ERB
        <option value="<%= value %>" <%= 'selected' if selected %> <%= 'disabled' if disabled %>>
          <%= label %>
        </option>
      ERB
    end
  end
end
