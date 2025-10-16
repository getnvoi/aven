# Google OAuth Implementation Documentation

## Overview

Google OAuth 2.0 integration for the Aven application. This implementation supports authentication using Google accounts (both personal Gmail accounts and Google Workspace accounts).

**Controller**: `app/controllers/aven/oauth/google_controller.rb`
**Routes**: `config/routes.rb:18-20`

---

## Default Scopes

```
openid email profile
```

### Scope Breakdown

| Scope | Purpose | Admin Consent Required |
|-------|---------|------------------------|
| `openid` | OpenID Connect authentication | No |
| `email` | Access user's email address | No |
| `profile` | Access user's basic profile (name, picture) | No |

**Note**: These are basic OAuth scopes that don't require admin approval. Users consent individually.

---

## OAuth 2.0 Flow

### 1. Authorization Request

**Endpoint**: `https://accounts.google.com/o/oauth2/v2/auth`

**Parameters**:
```ruby
{
  client_id: "YOUR_CLIENT_ID",
  redirect_uri: "https://yourdomain.com/oauth/google/callback",
  response_type: "code",
  scope: "openid email profile",
  state: "RANDOM_STATE_TOKEN",
  access_type: "offline",  # Optional: for refresh tokens
  prompt: "select_account" # Optional: force account selection
}
```

### 2. Token Exchange

**Endpoint**: `https://www.googleapis.com/oauth2/v4/token`

**Parameters**:
```ruby
{
  code: "AUTHORIZATION_CODE",
  client_id: "YOUR_CLIENT_ID",
  client_secret: "YOUR_CLIENT_SECRET",
  redirect_uri: "https://yourdomain.com/oauth/google/callback",
  grant_type: "authorization_code"
}
```

### 3. User Info Retrieval

**Endpoint**: `https://www.googleapis.com/oauth2/v3/userinfo`

**Response**:
```json
{
  "sub": "1234567890",
  "email": "user@gmail.com",
  "email_verified": true,
  "name": "John Doe",
  "picture": "https://lh3.googleusercontent.com/a/..."
}
```

---

## Configuration

### Application Configuration

```ruby
config.oauth_providers = {
  google: {
    client_id: ENV['GOOGLE_CLIENT_ID'],
    client_secret: ENV['GOOGLE_CLIENT_SECRET'],
    # Optional configurations:
    scope: "openid email profile",
    access_type: "offline",      # Receive refresh tokens
    prompt: "select_account"     # Force account selection
  }
}
```

### Environment Variables

```bash
GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-your_client_secret
```

---

## Google Cloud Console Setup

### 1. Create OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select or create a project
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. Select **Web application**
6. Configure:
   - **Name**: Your application name
   - **Authorized JavaScript origins**: `https://yourdomain.com`
   - **Authorized redirect URIs**: `https://yourdomain.com/oauth/google/callback`
7. Click **Create**
8. Copy the **Client ID** and **Client Secret**

### 2. Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** (for public apps) or **Internal** (for Google Workspace only)
3. Fill in:
   - **App name**: Your application name
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Add scopes (optional for basic profile)
5. Save and continue

### 3. Note Your Credentials

- **Client ID**: `123456789-...apps.googleusercontent.com`
- **Client Secret**: `GOCSPX-...`

---

## Routes

```ruby
# Google OAuth
get "google", to: "google#create", as: :google
get "google/callback", to: "google#callback", as: :google_callback
```

**Available Routes**:
- `GET /oauth/google` → Initiates OAuth flow
- `GET /oauth/google/callback` → Handles OAuth callback

**Named Routes**:
- `oauth_google_path` → `/oauth/google`
- `oauth_google_callback_path` → `/oauth/google/callback`

---

## Additional Scopes (Optional)

If you need access to more Google services, add these scopes:

### Gmail API

```ruby
scope: "openid email profile https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.send"
```

- `gmail.readonly` - Read emails
- `gmail.send` - Send emails
- `gmail.modify` - Read and modify emails

### Google Calendar

```ruby
scope: "openid email profile https://www.googleapis.com/auth/calendar.readonly"
```

- `calendar.readonly` - Read calendar events
- `calendar` - Full calendar access

### Google Drive

```ruby
scope: "openid email profile https://www.googleapis.com/auth/drive.readonly"
```

- `drive.readonly` - Read Drive files
- `drive.file` - Access files created by app
- `drive` - Full Drive access

**Important**: Extended scopes may require verification by Google if your app is public.

---

## Official Documentation

1. **Google OAuth 2.0 Guide**
   https://developers.google.com/identity/protocols/oauth2

2. **Using OAuth 2.0 to Access Google APIs**
   https://developers.google.com/identity/protocols/oauth2/web-server

3. **Google API Scopes**
   https://developers.google.com/identity/protocols/oauth2/scopes

4. **OpenID Connect**
   https://developers.google.com/identity/openid-connect/openid-connect

---

## Security Considerations

### Refresh Tokens

Set `access_type: "offline"` to receive refresh tokens for long-term access:

```ruby
access_type: oauth_config[:access_type] || "offline"
```

### Account Selection

Use `prompt: "select_account"` to force users to select which Google account to use:

```ruby
prompt: oauth_config[:prompt] || "select_account"
```

This is useful if users have multiple Google accounts.

---

## Troubleshooting

### "redirect_uri_mismatch"

**Solution**: Ensure the redirect URI in Google Cloud Console exactly matches:
```
https://yourdomain.com/oauth/google/callback
```

### "invalid_client"

**Solution**: Check that your Client ID and Client Secret are correct.

### "access_denied"

**Solution**: User declined the consent screen. This is normal user behavior.

---

**Last Updated**: October 15, 2025
