# Aven

Rails engine providing authentication, authorization, and application scaffolding.

## Architecture

Aven is a Rails engine mounted in host applications. It provides:
- Authentication (sessions, OAuth, magic links, password reset)
- Session management
- Articles/content management
- Workspaces and roles
- Agentic AI tools (agents, documents, MCP)
- Chat threads

## UI Components: Aeno Integration

**MANDATORY**: All views MUST use aeno components. No raw Tailwind classes for UI elements.

### How to Use Aeno

```erb
<%# Primitives - via ui() helper %>
<%= ui("button", label: "Submit", type: "submit") %>
<%= ui("input-text", name: "email", label: "Email", placeholder: "you@example.com") %>
<%= ui("alert", variant: :error, message: "Something went wrong") %>

<%# Blocks - via block() helper %>
<%= block("auth_card", title: "Sign in") do |card| %>
  <% card.with_alert do %>
    <%= ui("alert", variant: :error, message: alert) %>
  <% end %>
  <%# form content %>
  <% card.with_footer do %>
    <%# footer content %>
  <% end %>
<% end %>
```

### Available Aeno Components (sync manually)

#### Primitives (`ui("name", ...)`)

| Component | Description | Key Props |
|-----------|-------------|-----------|
| `alert` | Contextual feedback messages | `message:`, `variant:` (:default, :success, :warning, :error, :info), `title:`, `dismissible:` |
| `badge` | Status indicator | `label:`, `variant:` (:default, :success, :warning, :error, :info) |
| `button` | Action button | `label:`, `variant:` (:default, :outline, :ghost, :destructive), `type:`, `href:`, `full:` |
| `card` | Content container | `title:`, `subtitle:` |
| `divider` | Separator line | `label:` (optional centered text), `orientation:` |
| `drawer` | Slide-out panel | `title:`, `position:` |
| `dropdown` | Menu with items | `label:`, slots for items |
| `empty` | Empty state placeholder | `title:`, `description:`, `icon:` |
| `input-text` | Text input field | `name:`, `label:`, `placeholder:`, `value:`, `required:` |
| `input-password` | Password input | `name:`, `label:`, `placeholder:`, `required:` |
| `input-select` | Select dropdown | `name:`, `label:`, `options:` |
| `input-color` | Color picker | `name:`, `label:` |
| `input-slider` | Range slider | `name:`, `label:`, `min:`, `max:` |
| `input-tagging` | Tag input | `name:`, `label:` |
| `input-text-area` | Multiline text | `name:`, `label:`, `rows:` |
| `input-text-area-ai` | AI-enhanced textarea | `name:`, `label:` |
| `input-attachments` | File attachments | `name:` |
| `link` | Styled anchor | `label:`, `href:`, `variant:` (:default, :muted, :underline), `size:` |
| `list` | Card container with items | Block with `list.with_item` slots |
| `page` | Page layout wrapper | `title:` |
| `sidebar` | Navigation sidebar | Slots for sections |
| `spinner` | Loading indicator | `size:` |
| `table` | Data table | `columns:`, `rows:` |

#### Blocks (`block("name", ...)`)

| Component | Description | Key Props |
|-----------|-------------|-----------|
| `auth_card` | Full-screen centered auth container | `title:`, `subtitle:`, `max_width:` (:sm, :md, :lg), slots: `with_alert`, `with_footer` |
| `component_preview` | Component documentation preview | Internal use |

### Layout Requirements

In aven layouts, include:
```erb
<%= aeno_theme_tag %>
<%= stylesheet_link_tag "aeno/application", "data-turbo-track": "reload" %>
```

### CSS Variables for Theming

When inline styles are needed, use CSS variables:
```erb
style="color: var(--ui-foreground)"
style="color: var(--ui-muted-foreground)"
style="background-color: var(--ui-area-bg)"
style="color: var(--ui-heading-color)"
style="color: var(--ui-error)"
```

### Icons

Use lucide icons via the helper:
```erb
<%= lucide_icon("mail", class: "w-5 h-5") %>
```

## Features

### Authentication

#### Password Authentication (`auth/sessions`)
- Email/password sign in
- Session creation and management
- Links to password reset and magic link alternatives

#### Magic Links (`auth/magic_links`)
- Passwordless authentication via email
- 6-digit verification code
- Configurable expiration

#### Password Reset (`auth/password_resets`)
- Token-based password reset flow
- Email delivery of reset links
- Minimum password length enforcement

#### OAuth (`oauth/`)
Supported providers:
- GitHub
- Google
- Auth0
- Entra ID (Azure AD)

#### Session Management (`sessions/`)
- View active sessions across devices
- Device/browser detection
- Revoke individual or all sessions

### Content

#### Articles
- CRUD operations
- Tagging support
- Status management (draft, published)

### Workspaces

Multi-tenant workspace support with roles.

### Agentic AI

- Agents with tools
- Document management with embeddings
- MCP (Model Context Protocol) integration

## File Structure

```
app/
├── controllers/aven/
│   ├── auth/              # Password auth, magic links, password reset
│   ├── oauth/             # OAuth provider controllers
│   ├── agentic/           # AI agent controllers
│   ├── chat/              # Chat thread controllers
│   └── ...
├── components/aven/views/ # ViewComponent-based views
│   ├── auth/              # Auth view components
│   ├── oauth/             # OAuth views
│   ├── sessions/          # Session management views
│   └── articles/          # Article views
├── models/aven/
│   ├── session.rb         # User sessions
│   ├── magic_link.rb      # Magic link tokens
│   ├── article.rb         # Content
│   └── agentic/           # AI models
└── ...
```

## Testing

```bash
bundle exec rake test
```

## Development

Aven depends on aeno for UI components. For local development:

```bash
# Set local aeno path (keeps Gemfile clean)
bundle config local.aeno /path/to/aeno

# Verify it's using local
bundle info aeno  # Should show local path
```
