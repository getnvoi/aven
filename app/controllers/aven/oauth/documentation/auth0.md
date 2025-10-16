# Auth0 OAuth Implementation Documentation

## Overview

Auth0 OAuth 2.0 integration for the Aven application. Auth0 is an identity-as-a-service platform that supports multiple identity providers (social, enterprise, database) through a single integration.

**Controller**: `app/controllers/aven/oauth/auth0_controller.rb`
**Routes**: `config/routes.rb:26-28`

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
| `profile` | Access user's basic profile | No |

**Note**: These are standard OIDC scopes. Auth0 doesn't require admin approval for these basic scopes.

---

## OAuth 2.0 Flow

### 1. Authorization Request

**Endpoint**: `https://{your-domain}.auth0.com/authorize`

**Parameters**:
```ruby
{
  client_id: "YOUR_CLIENT_ID",
  redirect_uri: "https://yourdomain.com/oauth/auth0/callback",
  response_type: "code",
  scope: "openid email profile",
  state: "RANDOM_STATE_TOKEN",
  audience: "YOUR_API_IDENTIFIER" # Optional: for API access
}
```

### 2. Token Exchange

**Endpoint**: `https://{your-domain}.auth0.com/oauth/token`

**Parameters**:
```ruby
{
  grant_type: "authorization_code",
  client_id: "YOUR_CLIENT_ID",
  client_secret: "YOUR_CLIENT_SECRET",
  code: "AUTHORIZATION_CODE",
  redirect_uri: "https://yourdomain.com/oauth/auth0/callback"
}
```

### 3. User Info Retrieval

**Endpoint**: `https://{your-domain}.auth0.com/userinfo`

**Response**:
```json
{
  "sub": "auth0|1234567890abcdef",
  "email": "user@example.com",
  "email_verified": true,
  "name": "John Doe",
  "nickname": "johndoe",
  "picture": "https://s.gravatar.com/avatar/..."
}
```

---

## Configuration

### Application Configuration

```ruby
config.oauth_providers = {
  auth0: {
    client_id: ENV['AUTH0_CLIENT_ID'],
    client_secret: ENV['AUTH0_CLIENT_SECRET'],
    domain: ENV['AUTH0_DOMAIN'], # e.g., "your-tenant.auth0.com"
    # Optional configurations:
    scope: "openid email profile",
    audience: ENV['AUTH0_AUDIENCE'] # Optional: for API access
  }
}
```

### Environment Variables

```bash
AUTH0_CLIENT_ID=a1b2c3d4e5f6g7h8i9j0k1l2
AUTH0_CLIENT_SECRET=A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_AUDIENCE=https://yourapi.com/api  # Optional
```

---

## Auth0 Application Setup

### 1. Create Application

1. Go to [Auth0 Dashboard](https://manage.auth0.com)
2. Navigate to **Applications** > **Applications**
3. Click **Create Application**
4. Choose:
   - **Name**: Your application name
   - **Application Type**: Regular Web Application
5. Click **Create**

### 2. Configure Application Settings

1. Go to **Settings** tab
2. Configure:
   - **Allowed Callback URLs**: `https://yourdomain.com/oauth/auth0/callback`
   - **Allowed Logout URLs**: `https://yourdomain.com`
   - **Allowed Web Origins**: `https://yourdomain.com`
3. Scroll to bottom and click **Save Changes**

### 3. Note Your Credentials

In the **Settings** tab:
- **Domain**: `your-tenant.auth0.com` (or custom domain)
- **Client ID**: `a1b2c3d4e5f6g7h8i9j0k1l2`
- **Client Secret**: `A1B2C3D4E5...` (click "Show" to reveal)

### 4. Configure Connections (Optional)

Enable identity providers in **Authentication** > **Social** or **Enterprise**:
- Google
- Facebook
- GitHub
- Microsoft
- SAML
- Active Directory
- And many more...

---

## Routes

```ruby
# Auth0 OAuth
get "auth0", to: "auth0#create", as: :auth0
get "auth0/callback", to: "auth0#callback", as: :auth0_callback
```

**Available Routes**:
- `GET /oauth/auth0` → Initiates OAuth flow
- `GET /oauth/auth0/callback` → Handles OAuth callback

**Named Routes**:
- `oauth_auth0_path` → `/oauth/auth0`
- `oauth_auth0_callback_path` → `/oauth/auth0/callback`

---

## Auth0 Domains

### Tenant Domains

Auth0 provides different domain formats:

| Domain Type | Format | Example |
|-------------|--------|---------|
| US Tenant | `{tenant}.auth0.com` | `myapp.auth0.com` |
| EU Tenant | `{tenant}.eu.auth0.com` | `myapp.eu.auth0.com` |
| AU Tenant | `{tenant}.au.auth0.com` | `myapp.au.auth0.com` |
| Custom Domain | Your own domain | `auth.yourdomain.com` |

### Custom Domains

For production, you can configure a custom domain:
1. Go to **Branding** > **Custom Domains**
2. Follow setup instructions
3. Update `AUTH0_DOMAIN` to your custom domain

Benefits:
- Consistent branding
- First-party cookies
- Better user experience

---

## Additional Scopes (Optional)

### API Access

To call your own API protected by Auth0:

```ruby
config.oauth_providers = {
  auth0: {
    # ... other config
    audience: "https://yourapi.com/api",
    scope: "openid email profile read:data write:data"
  }
}
```

The `audience` parameter ensures the access token is valid for your API.

### Offline Access

For refresh tokens:

```ruby
scope: "openid email profile offline_access"
```

This allows you to get a refresh token to obtain new access tokens.

---

## Auth0 Management API

After authentication, you can call the Auth0 Management API for advanced user management:

### Get User Details

```ruby
GET https://your-tenant.auth0.com/api/v2/users/{user_id}
Authorization: Bearer {management_api_token}
```

**Note**: Requires a Management API token (different from user access token).

### Update User Metadata

```ruby
PATCH https://your-tenant.auth0.com/api/v2/users/{user_id}
Authorization: Bearer {management_api_token}
Content-Type: application/json

{
  "user_metadata": {
    "preference": "dark_mode"
  }
}
```

---

## Official Documentation

1. **Auth0 OAuth 2.0 Guide**
   https://auth0.com/docs/authenticate/protocols/oauth

2. **Auth0 Authorization Code Flow**
   https://auth0.com/docs/get-started/authentication-and-authorization-flow/authorization-code-flow

3. **Auth0 Scopes**
   https://auth0.com/docs/get-started/apis/scopes

4. **Auth0 Management API**
   https://auth0.com/docs/api/management/v2

5. **Auth0 Custom Domains**
   https://auth0.com/docs/customize/custom-domains

---

## Advanced Features

### Social Connections

Auth0 allows you to enable multiple social providers without additional integration:

**Available Providers**:
- Google
- Facebook
- GitHub
- Microsoft
- Twitter
- LinkedIn
- And 30+ more...

Users see a unified login screen and can choose their preferred provider.

### Enterprise Connections

For B2B applications:
- **SAML**: Integrate with enterprise identity providers
- **Active Directory/LDAP**: Connect to on-premise directories
- **Azure AD**: Microsoft enterprise authentication
- **OIDC**: Any OpenID Connect provider

### Multi-Factor Authentication (MFA)

Enable MFA in Auth0 Dashboard:
1. Go to **Security** > **Multi-factor Auth**
2. Enable factors (SMS, authenticator app, email)
3. Configure policies (always on, adaptive, optional)

### Custom Login Pages

Customize the login experience:
1. Go to **Branding** > **Universal Login**
2. Choose template or customize HTML/CSS
3. Match your brand identity

---

## Troubleshooting

### "callback URL mismatch"

**Solution**: Ensure the callback URL in Auth0 Application Settings exactly matches:
```
https://yourdomain.com/oauth/auth0/callback
```

Auth0 is strict about trailing slashes and protocols.

### "invalid_grant"

**Solution**: The authorization code has expired or been used. Codes expire after 10 minutes. Ask user to try again.

### "unauthorized_client"

**Solution**:
- Check that grant type is enabled in Auth0 Application settings
- Ensure Application Type is "Regular Web Application"

### "access_denied"

**Solution**: User declined consent or doesn't have access. This is normal user behavior.

---

## Security Considerations

### Token Expiration

Auth0 access tokens expire by default:
- **Access Token**: 24 hours (configurable)
- **ID Token**: Used for authentication only
- **Refresh Token**: Use `offline_access` scope

### Token Storage

The implementation stores the access token:

```ruby
user.access_token = token_data[:access_token]
```

**Recommendations**:
1. Encrypt the `access_token` column
2. Store `refresh_token` if using `offline_access`
3. Implement token refresh logic before expiration

### State Parameter

The implementation uses CSRF protection via state parameter:

```ruby
state = SecureRandom.hex(16)
session[:oauth_state] = state
```

This prevents cross-site request forgery attacks.

---

## Migration from Other Providers

Auth0 can help migrate users from:
- Custom database authentication
- Other identity providers
- Social logins

This allows gradual migration without forcing password resets.

---

**Last Updated**: October 15, 2025
