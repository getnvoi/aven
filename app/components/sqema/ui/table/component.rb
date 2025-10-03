module Sqema::Ui::Table
  class Component < ::Sqema::ApplicationViewComponent
    option(:css, optional: true)
    option(:id, optional: true)

    renders_one :header, "HeaderComponent"
    renders_many :rows, "RowComponent"

    class HeaderComponent < Sqema::ApplicationViewComponent
      renders_many :columns, "ColumnComponent"

      class ColumnComponent < Sqema::ApplicationViewComponent
        option(:css, optional: true)

        erb_template <<~ERB
          <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider <%= css %>">
            <%= content %>
          </th>
        ERB
      end

      erb_template <<~ERB
        <thead class="bg-gray-50">
          <tr>
            <% columns.each do |column| %>
              <%= column %>
            <% end %>
          </tr>
        </thead>
      ERB
    end

    class RowComponent < Sqema::ApplicationViewComponent
      option(:css, optional: true)

      renders_many :cells, "CellComponent"

      class CellComponent < Sqema::ApplicationViewComponent
        option(:css, optional: true)

        erb_template <<~ERB
          <td class="px-6 py-4 text-sm text-gray-900 <%= css %>">
            <%= content %>
          </td>
        ERB
      end

      erb_template <<~ERB
        <tr class="<%= css %>">
          <% cells.each do |cell| %>
            <%= cell %>
          <% end %>
        </tr>
      ERB
    end

    def table_classes
      [
        "min-w-full divide-y divide-gray-200",
        css
      ].compact.join(" ")
    end
  end
end
