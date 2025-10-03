module Sqema::Ui::Dropdown
  class Component < ::Sqema::ApplicationViewComponent
    option(:css, optional: true)
    option(:label, optional: true)
    option(:button_variant, default: proc { :white })
    option(:button_size, default: proc { :small })

    renders_many :options, "OptionComponent"
    renders_many :groups, "GroupComponent"

    class OptionComponent < ApplicationViewComponent
      option(:value)
      option(:label)
      option(:href, optional: true)
      option(:selected, default: proc { false })
      option(:icon, optional: true)

      erb_template <<~ERB
        <% if href %>
          <a href="<%= href %>"
             class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900 <%= 'bg-gray-50' if selected %>"
             role="menuitem">
            <div class="flex items-center space-x-2">
              <%= lucide_icon(icon, class: "w-4 h-4") if icon %>
              <span><%= label %></span>
            </div>
          </a>
        <% else %>
          <button type="button"
                  data-value="<%= value %>"
                  class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900 <%= 'bg-gray-50' if selected %>"
                  role="menuitem">
            <div class="flex items-center space-x-2">
              <%= lucide_icon(icon, class: "w-4 h-4") if icon %>
              <span><%= label %></span>
            </div>
          </button>
        <% end %>
      ERB
    end

    class GroupComponent < ApplicationViewComponent
      option(:label)

      renders_many :items, "Ui::Dropdown::Component::OptionComponent"

      erb_template <<~ERB
        <div class="py-1">
          <div class="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">
            <%= label %>
          </div>
          <% items.each do |item| %>
            <%= item %>
          <% end %>
        </div>
      ERB
    end

    def classes
      [
        "relative inline-block text-left",
        css
      ].join(" ")
    end
  end
end
