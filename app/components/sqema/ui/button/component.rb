module Sqema::Ui::Button
  class Component < ::Sqema::ApplicationViewComponent
    option(:css, optional: true)
    option(:type, optional: true)
    option(:label, optional: true)
    option(:method, optional: true)
    option(:href, optional: true)
    option(:data, default: proc { {} })
    option(:icon, optional: true)
    option(:variant, default: proc { :default })
    option(:disabled, default: proc { false })
    option(:full, default: proc { false })
    option(:size, default: proc { nil })
    option(:as, default: proc { :button })
    option(:target, optional: true)

    style do
      base do
        %w[
          rounded-md
          px-3.5
          py-2.5
          text-base
          font-semibold
          inline-flex
          items-center
          space-x-1
          hover:bg-stone-500
          focus-visible:outline
          focus-visible:outline-2
          focus-visible:outline-offset-2
          focus-visible:outline-stone-600
          cursor-pointer
          [&>span]:truncate
          [&>span]:flex-shrink
          [&>svg]:flex-shrink-0
          [&>svg]:w-4
          [&>svg]:h-4
          [&.loading]:opacity-50
          [&.loading]:pointer-events-none
          [&.loading_.icon]:hidden
          [&.loading_.spinner]:flex
        ]
      end

      variants do
        variant do
          white { "text-stone-600 bg-white hover:bg-stone-50 text-stone-800 border border-gray-200 shadow-sm !text-gray-500" }
          default { "bg-stone-600 text-white" }
          light { "bg-stone-50 text-stone-600 hover:bg-stone-100" }
          outline { "bg-stone-50 text-stone-600 ring ring-1 ring-stone-400 rounded-full px-6 hover:bg-stone-100" }
        end

        disabled do
          yes { "pointer-events-none opacity-50" }
        end

        full do
          yes { "w-full justify-center" }
        end

        size do
          xsmall do
            %w[
              px-2.5
              py-1
              [&>span]:text-xs
              [&>svg]:pl-[-10px]
              [&>svg]:flex-shrink-0
              [&>svg]:w-3
              [&>svg]:h-3
              space-x-1
            ]
          end

          small do
            %w[
              text-lg
              px-2.5
              py-1.5
              space-x-1
              text-sm
              [&>svg]:pl-[-10px]
              [&>svg]:flex-shrink-0
              [&>svg]:w-4
              [&>svg]:h-4
            ]
          end

          large do
            %w[
              text-lg
              px-4
              py-3
              space-x-2
              [&>svg]:pl-[-10px]
              [&>svg]:flex-shrink-0
              [&>svg]:w-6
              [&>svg]:h-6
            ]
          end
        end
      end
    end

    def classes
      [
        css,
        style(variant:, disabled:, full:, size:)
      ].join(" ")
    end

    erb_template <<~ERB
      <% if href %>
        <%= link_to(href, method:, data: merged_data, class: classes, target:) do %>
          <%= lucide_icon(icon, class: "flex-shrink-0 icon") if icon %>
          <%= ui("spinner", size: :sm, variant: :white, css: "spinner hidden") %>
          <% if label %><span class="truncate flex-shrink"><%= label %></span><% end %>
        <% end %>
      <% else %>
        <%= content_tag(as, data: merged_data, type: type || "button", class: classes) do %>
          <%= lucide_icon(icon, class: "flex-shrink-0 icon") if icon %>
          <%= ui("spinner", size: :sm,  variant: :white, css: "spinner hidden") %>
          <% if label %><span class="truncate flex-shrink"><%= label %></span><% end %>
        <% end %>
      <% end %>
    ERB
  end
end
