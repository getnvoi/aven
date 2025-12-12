# Plan: Port Item System to Aven

## Overview

Port the flexible Item schema system from formblocks into Aven as a reusable Rails engine component. Items will be workspace-scoped via `TenantModel`.

## Key Adaptations

| Formblocks | Aven |
|------------|------|
| `user_id` scoping | `workspace_id` via TenantModel |
| `Item` | `Aven::Item` |
| `ItemLink` | `Aven::ItemLink` |
| `Item::Schemas::Contact` | `Aven::Item::Schemas::Contact` (example) |
| Tables: `items`, `item_links` | Tables: `aven_items`, `aven_item_links` |

## Files to Create

### Migrations
```
db/migrate/20200101000009_create_aven_items.rb
db/migrate/20200101000010_create_aven_item_links.rb
```

### Models
```
app/models/aven/item.rb
app/models/aven/item_link.rb
app/models/aven/item/embed.rb
app/models/aven/item/schemaed.rb
app/models/aven/item/embeddable.rb
app/models/aven/item/linkable.rb
app/models/aven/item/schema/builder.rb
app/models/aven/item/schemas/base.rb
```

### Tests
```
test/models/aven/item_test.rb
test/models/aven/item_link_test.rb
test/models/aven/item/embed_test.rb
test/models/aven/item/schemaed_test.rb
test/models/aven/item/embeddable_test.rb
test/models/aven/item/linkable_test.rb
test/models/aven/item/schema/builder_test.rb
```

## Implementation Steps

### 1. Migrations

**aven_items:**
- `workspace_id` (bigint, not null, FK to aven_workspaces)
- `schema_slug` (string, not null) - identifies schema class
- `data` (jsonb, not null, default {})
- `deleted_at` (datetime, nullable) - soft delete
- `timestamps`
- Indexes: workspace_id, schema_slug, data (GIN), deleted_at

**aven_item_links:**
- `source_id` (bigint, not null, FK to aven_items)
- `target_id` (bigint, not null, FK to aven_items)
- `relation` (string, not null) - e.g. "company", "notes"
- `position` (integer, default 0) - ordering for has_many
- `timestamps`
- Indexes: [source_id, relation], [target_id, relation], unique [source_id, target_id, relation]

### 2. Aven::Item Model

```ruby
module Aven
  class Item < ApplicationRecord
    include Aven::Model::TenantModel
    include Aven::Loggable
    include Item::Schemaed
    include Item::Embeddable
    include Item::Linkable

    self.table_name = "aven_items"

    validates :schema_slug, presence: true
    validates :data, presence: true

    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
    scope :by_schema, ->(slug) { where(schema_slug: slug) }
    scope :recent, -> { order(created_at: :desc) }

    def soft_delete!
      update!(deleted_at: Time.current)
    end

    def restore!
      update!(deleted_at: nil)
    end

    def deleted?
      deleted_at.present?
    end

    class << self
      def schema_class_for(slug)
        "Aven::Item::Schemas::#{slug.to_s.camelize}".constantize
      rescue NameError
        nil
      end

      def schema_for(slug)
        schema_class_for(slug)&.builder
      end
    end

    def schema_class
      self.class.schema_class_for(schema_slug)
    end

    def schema_builder
      schema_class&.builder
    end
  end
end
```

### 3. Aven::ItemLink Model

```ruby
module Aven
  class ItemLink < ApplicationRecord
    self.table_name = "aven_item_links"

    belongs_to :source, class_name: "Aven::Item"
    belongs_to :target, class_name: "Aven::Item"

    validates :relation, presence: true
    validates :target_id, uniqueness: { scope: [:source_id, :relation] }

    scope :for_relation, ->(rel) { where(relation: rel) }
    scope :ordered, -> { order(position: :asc) }

    # Workspace accessed via source item
    delegate :workspace, :workspace_id, to: :source
  end
end
```

### 4. Concerns (under app/models/aven/item/)

**Schemaed** - Dynamic accessors for fields, embeds, links based on schema_slug
**Embeddable** - JSONB embedded documents with `_attributes=` support
**Linkable** - ItemLink management with `*_id=` and `*_ids=` setters

### 5. Schema DSL (under app/models/aven/item/schema/)

**Builder** - DSL for defining fields, embeds, links
**Base** - Base class for schema definitions with query helpers

### 6. Embed Class

Wrapper for embedded JSONB documents with attribute accessors.

### 7. Integration with Workspace

Since Item includes TenantModel:
- `workspace.items` automatically available
- `Item.in_workspace(workspace)` scope available
- `item.workspace` association available

### 8. Example Schema Definition

Host apps can define schemas:

```ruby
# In host app: app/models/aven/item/schemas/contact.rb
module Aven
  class Item::Schemas::Contact < Item::Schemas::Base
    string :first_name, required: true
    string :last_name
    string :email

    embeds_many :addresses do
      string :street
      string :city
      string :postal_code
    end

    links_one :company
    links_many :notes
  end
end
```

## Testing Strategy

Use Aven's existing minitest setup:
- Unit tests for each model/concern
- Test workspace scoping via TenantModel
- Test schema DSL building
- Test embedded document handling
- Test link creation/querying

## Order of Implementation

1. Migrations (create tables)
2. ItemLink model (simpler, no concerns)
3. Item::Schema::Builder (DSL foundation)
4. Item::Embed (simple wrapper)
5. Item::Schemas::Base (schema base class)
6. Item::Schemaed concern (field/embed/link accessors)
7. Item::Embeddable concern (embed attribute handling)
8. Item::Linkable concern (link persistence)
9. Item model (brings it all together)
10. Tests for each component
