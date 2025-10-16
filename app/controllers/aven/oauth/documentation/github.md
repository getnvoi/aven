# GitHub OAuth Implementation Documentation

## Overview

GitHub OAuth 2.0 integration for the Aven application. This implementation supports authentication using GitHub accounts.

**Controller**: `app/controllers/aven/oauth/github_controller.rb`
**Routes**: `config/routes.rb:22-24`

---

## Default Scopes

```
user:email
```

### Scope Breakdown

| Scope | Purpose | Description |
|-------|---------|-------------|
| `user:email` | Read email addresses | Grants read-only access to user's email addresses (including private emails) |

**Note**: GitHub scopes don't require admin approval. Users consent individually.

---

## OAuth 2.0 Flow

### 1. Authorization Request

**Endpoint**: `https://github.com/login/oauth/authorize`

**Parameters**:
```ruby
{
  client_id: "YOUR_CLIENT_ID",
  redirect_uri: "https://yourdomain.com/oauth/github/callback",
  scope: "user:email",
  state: "RANDOM_STATE_TOKEN"
}
```

### 2. Token Exchange

**Endpoint**: `https://github.com/login/oauth/access_token`

**Parameters**:
```ruby
{
  client_id: "YOUR_CLIENT_ID",
  client_secret: "YOUR_CLIENT_SECRET",
  code: "AUTHORIZATION_CODE",
  redirect_uri: "https://yourdomain.com/oauth/github/callback"
}
```

**Headers**:
```ruby
{
  "Accept" => "application/json"
}
```

### 3. User Info Retrieval

**User Profile Endpoint**: `https://api.github.com/user`

**Response**:
```json
{
  "id": 12345678,
  "login": "johndoe",
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://avatars.githubusercontent.com/u/12345678",
  "bio": "Developer",
  "company": "Acme Inc"
}
```

**User Emails Endpoint**: `https://api.github.com/user/emails`

Used when public email is not available.

**Response**:
```json
[
  {
    "email": "john@example.com",
    "primary": true,
    "verified": true,
    "visibility": "private"
  }
]
```

**Implementation Logic**:
- First tries to get email from user profile
- If email is null/blank, fetches from `/user/emails` endpoint
- Uses the primary verified email

---

## Configuration

### Application Configuration

```ruby
config.oauth_providers = {
  github: {
    client_id: ENV['GITHUB_CLIENT_ID'],
    client_secret: ENV['GITHUB_CLIENT_SECRET'],
    # Optional configurations:
    scope: "user:email read:user"
  }
}
```

### Environment Variables

```bash
GITHUB_CLIENT_ID=Iv1.a1b2c3d4e5f6g7h8
GITHUB_CLIENT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

---

## GitHub OAuth App Setup

### 1. Create OAuth App

1. Go to [GitHub Settings](https://github.com/settings/developers)
2. Click **OAuth Apps** > **New OAuth App**
3. Fill in:
   - **Application name**: Your application name
   - **Homepage URL**: `https://yourdomain.com`
   - **Authorization callback URL**: `https://yourdomain.com/oauth/github/callback`
   - **Application description**: (optional)
4. Click **Register application**
5. Copy the **Client ID**
6. Click **Generate a new client secret**
7. Copy the **Client Secret** (shown only once)

### 2. Note Your Credentials

- **Client ID**: `Iv1.a1b2c3d4e5f6g7h8`
- **Client Secret**: `a1b2c3d4e5f6g7h8i9j0...`

---

## Routes

```ruby
# GitHub OAuth
get "github", to: "github#create", as: :github
get "github/callback", to: "github#callback", as: :github_callback
```

**Available Routes**:
- `GET /oauth/github` → Initiates OAuth flow
- `GET /oauth/github/callback` → Handles OAuth callback

**Named Routes**:
- `oauth_github_path` → `/oauth/github`
- `oauth_github_callback_path` → `/oauth/github/callback`

---

## Additional Scopes (Optional)

### User Information

```ruby
scope: "user:email read:user"
```

- `read:user` - Read all user profile data
- `user` - Full access to user profile (read and write)

### Repository Access

```ruby
scope: "user:email repo"
```

- `repo` - Full control of private repositories
- `public_repo` - Access to public repositories only

### Organization Access

```ruby
scope: "user:email read:org"
```

- `read:org` - Read org and team membership
- `write:org` - Manage org and teams

### Gist Access

```ruby
scope: "user:email gist"
```

- `gist` - Create and edit gists

---

## GitHub API Usage

After authentication, use the access token to call GitHub API v3:

### Get User Repositories

```ruby
GET https://api.github.com/user/repos
Authorization: Bearer {access_token}
Accept: application/vnd.github.v3+json
```

### Get User Organizations

```ruby
GET https://api.github.com/user/orgs
Authorization: Bearer {access_token}
Accept: application/vnd.github.v3+json
```

### Get Authenticated User

```ruby
GET https://api.github.com/user
Authorization: Bearer {access_token}
Accept: application/vnd.github.v3+json
```

---

## Official Documentation

1. **GitHub OAuth Documentation**
   https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps

2. **GitHub API Documentation**
   https://docs.github.com/en/rest

3. **GitHub OAuth Scopes**
   https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps

4. **GitHub REST API - Users**
   https://docs.github.com/en/rest/users/users

---

## Implementation Details

### Email Handling

The implementation has special logic for retrieving emails:

```ruby
# Fetch user profile
user_data = github_api_request(USER_INFO_URL, access_token)

# Fetch primary email if not public
email = user_data[:email]
if email.blank?
  emails_data = github_api_request(USER_EMAIL_URL, access_token)
  primary_email = emails_data.find { |e| e[:primary] && e[:verified] }
  email = primary_email[:email] if primary_email
end
```

This ensures we always get an email, even if the user's GitHub email is private.

### API Request Headers

GitHub requires specific headers:

```ruby
request["Authorization"] = "Bearer #{access_token}"
request["Accept"] = "application/vnd.github.v3+json"
```

---

## Troubleshooting

### "redirect_uri_mismatch"

**Solution**: Ensure the callback URL in your GitHub OAuth App settings exactly matches:
```
https://yourdomain.com/oauth/github/callback
```

### "bad_verification_code"

**Solution**: The authorization code has already been used or expired. Ask user to try again.

### No email returned

**Solution**: Ensure you're requesting the `user:email` scope. The implementation will fallback to the `/user/emails` endpoint.

### API rate limiting

**Solution**: Authenticated requests have a limit of 5,000 requests per hour. For unauthenticated requests, it's 60 per hour.

---

## Security Considerations

### Token Expiration

GitHub access tokens **do not expire** by default (unlike other OAuth providers). This means:
- Tokens remain valid until manually revoked
- No need for refresh token logic
- Important to handle token revocation properly

Users can revoke access at: https://github.com/settings/applications

### Scope Permissions

Request only the minimum scopes needed:
- ✅ `user:email` - For authentication only
- ❌ `repo` - Don't request unless you need repository access

---

**Last Updated**: October 15, 2025
