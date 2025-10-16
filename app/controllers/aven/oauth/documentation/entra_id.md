# Microsoft Entra ID OAuth Implementation Documentation

## Overview

Microsoft Entra ID (formerly Azure Active Directory) OAuth 2.0 integration for the Aven application. This implementation supports authentication and authorization for Microsoft work/school accounts and personal Microsoft accounts.

**Implementation Date**: October 15, 2025
**Controller**: `app/controllers/aven/oauth/entra_id_controller.rb`
**Routes**: `config/routes.rb:30-32`

---

## Default Scopes

The implementation uses the following default scopes:

```
openid email profile User.Read Contacts.Read Mail.Send Mail.Read
```

### Scope Breakdown

| Scope           | Purpose                         | Admin Consent Required | Verified Source                                                                              |
| --------------- | ------------------------------- | ---------------------- | -------------------------------------------------------------------------------------------- |
| `openid`        | OpenID Connect authentication   | No                     | [OAuth 2.0 Scopes](https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc)    |
| `email`         | Access user's email address     | No                     | [OAuth 2.0 Scopes](https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc)    |
| `profile`       | Access user's basic profile     | No                     | [OAuth 2.0 Scopes](https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc)    |
| `User.Read`     | Read user's profile information | No                     | [Microsoft Graph Permissions](https://learn.microsoft.com/en-us/graph/permissions-reference) |
| `Contacts.Read` | Read user's contacts            | No                     | [List Contacts API](https://learn.microsoft.com/en-us/graph/api/user-list-contacts)          |
| `Mail.Send`     | Send email as the user          | No\*                   | [Send Mail API](https://learn.microsoft.com/en-us/graph/api/user-sendmail)                   |
| `Mail.Read`     | Read user's email               | No\*                   | [List Messages API](https://learn.microsoft.com/en-us/graph/api/user-list-messages)          |

**Note**: "Admin Consent Required: No" means users can consent individually. However, organization admins may configure policies requiring admin pre-approval.

---

## Admin Consent Explanation

### What is Admin Consent?

**User Consent (Default)**:

- Individual users can grant permissions when they sign in
- No administrator involvement needed
- Works for personal Microsoft accounts and smaller organizations

**Admin Consent Override**:
Organizations can configure policies that require administrator approval even for normally user-consentable permissions:

- **Tenant-wide settings**: Admins can disable user consent entirely
- **Pre-approval**: Admins can grant permissions on behalf of all users
- **Restricted permissions**: Certain sensitive permissions always require admin consent

### When Admin Consent is Needed

1. **Enterprise Organizations**: Many large companies disable user consent
2. **Sensitive Permissions**: Higher-privilege permissions always need admin approval
3. **Policy Requirements**: Compliance or security policies may mandate admin review
4. **Shared Permissions**: Accessing shared mailboxes/resources (e.g., `Mail.Read.Shared`)

---

## OAuth 2.0 Flow

### 1. Authorization Request

**Endpoint**: `https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/authorize`

**Parameters**:

```ruby
{
  client_id: "YOUR_CLIENT_ID",
  redirect_uri: "https://yourdomain.com/oauth/entra_id/callback",
  response_type: "code",
  scope: "openid email profile User.Read Contacts.Read Mail.Send Mail.Read",
  state: "RANDOM_STATE_TOKEN",
  response_mode: "query"
}
```

**Optional Parameters**:

- `domain_hint`: Pre-fills login with a specific domain (e.g., "contoso.com")
- `prompt`: Controls the prompt behavior (e.g., "select_account", "consent")

### 2. Token Exchange

**Endpoint**: `https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token`

**Parameters**:

```ruby
{
  client_id: "YOUR_CLIENT_ID",
  client_secret: "YOUR_CLIENT_SECRET",
  code: "AUTHORIZATION_CODE",
  redirect_uri: "https://yourdomain.com/oauth/entra_id/callback",
  grant_type: "authorization_code",
  scope: "openid email profile User.Read Contacts.Read Mail.Send Mail.Read"
}
```

**Response**:

```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJub25jZSI6...",
  "token_type": "Bearer",
  "expires_in": 3599,
  "scope": "openid email profile User.Read Contacts.Read Mail.Send Mail.Read",
  "refresh_token": "0.AXEA...",
  "id_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### 3. User Info Retrieval

**Endpoint**: `https://graph.microsoft.com/v1.0/me`

**Response**:

```json
{
  "id": "48d31887-5fad-4d73-a9f5-3c356e68a038",
  "displayName": "John Doe",
  "mail": "john.doe@contoso.com",
  "userPrincipalName": "john.doe@contoso.com"
}
```

**Mapping in Controller**:

```ruby
{
  id: response[:id] || response[:sub],
  email: response[:mail] || response[:userPrincipalName] || response[:email],
  name: response[:displayName] || response[:name],
  picture: nil
}
```

---

## Configuration

### Application Configuration

In your Aven initializer or configuration:

```ruby
config.oauth_providers = {
  entra_id: {
    client_id: ENV['ENTRA_ID_CLIENT_ID'],
    client_secret: ENV['ENTRA_ID_CLIENT_SECRET'],
    tenant_id: ENV['ENTRA_ID_TENANT_ID'], # or "common" for multi-tenant
    # Optional configurations:
    scope: "openid email profile User.Read Contacts.Read Mail.Send Mail.Read",
    domain_hint: "yourdomain.com", # Pre-fills login domain
    prompt: "select_account" # Forces account selection
  }
}
```

### Tenant ID Options

| Tenant ID       | Use Case               | Behavior                                            |
| --------------- | ---------------------- | --------------------------------------------------- |
| `common`        | Multi-tenant           | Allows any Microsoft account (work/school/personal) |
| `organizations` | Work/school only       | Allows only organizational accounts                 |
| `consumers`     | Personal accounts only | Allows only personal Microsoft accounts             |
| `{tenant-guid}` | Single tenant          | Restricts to specific Azure AD tenant               |

### Environment Variables

```bash
ENTRA_ID_CLIENT_ID=12345678-1234-1234-1234-123456789abc
ENTRA_ID_CLIENT_SECRET=your_client_secret_value
ENTRA_ID_TENANT_ID=common
```

---

## Azure App Registration Setup

### 1. Create App Registration

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Click **New registration**
4. Configure:
   - **Name**: Your application name
   - **Supported account types**:
     - Single tenant (your organization only)
     - Multi-tenant (any organization)
     - Multi-tenant + personal Microsoft accounts
   - **Redirect URI**: `https://yourdomain.com/oauth/entra_id/callback`

### 2. Configure API Permissions

1. Go to **API permissions** in your app registration
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Select **Delegated permissions**
5. Add the following permissions:
   - `User.Read` (usually added by default)
   - `Contacts.Read`
   - `Mail.Send`
   - `Mail.Read`
6. (Optional) Click **Grant admin consent** to pre-approve for all users

### 3. Create Client Secret

1. Go to **Certificates & secrets**
2. Click **New client secret**
3. Add a description and select expiration
4. **Copy the secret value immediately** (it won't be shown again)
5. Store in `ENTRA_ID_CLIENT_SECRET` environment variable

### 4. Note Your IDs

- **Application (client) ID**: Found on Overview page → `ENTRA_ID_CLIENT_ID`
- **Directory (tenant) ID**: Found on Overview page → `ENTRA_ID_TENANT_ID`

---

## Microsoft Graph API Usage

After successful authentication, the `access_token` is stored in `user.access_token` and can be used to call Microsoft Graph APIs.

### Read Contacts

```ruby
GET https://graph.microsoft.com/v1.0/me/contacts
Authorization: Bearer {access_token}
```

**Response**:

```json
{
  "value": [
    {
      "id": "AAMkAGI2T...",
      "displayName": "Jane Smith",
      "emailAddresses": [
        {
          "address": "jane.smith@example.com",
          "name": "Jane Smith"
        }
      ]
    }
  ]
}
```

**Documentation**: https://learn.microsoft.com/en-us/graph/api/user-list-contacts

### Send Email

```ruby
POST https://graph.microsoft.com/v1.0/me/sendMail
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "message": {
    "subject": "Hello from Aven",
    "body": {
      "contentType": "Text",
      "content": "This is a test email."
    },
    "toRecipients": [
      {
        "emailAddress": {
          "address": "recipient@example.com"
        }
      }
    ]
  }
}
```

**Documentation**: https://learn.microsoft.com/en-us/graph/api/user-sendmail

### Read Email

```ruby
GET https://graph.microsoft.com/v1.0/me/messages
Authorization: Bearer {access_token}
```

**Optional Query Parameters**:

- `$select=subject,from,receivedDateTime,bodyPreview`
- `$filter=isRead eq false`
- `$orderby=receivedDateTime desc`
- `$top=10`

**Response**:

```json
{
  "value": [
    {
      "id": "AAMkAGI2T...",
      "subject": "Meeting Tomorrow",
      "from": {
        "emailAddress": {
          "name": "John Doe",
          "address": "john@example.com"
        }
      },
      "receivedDateTime": "2025-10-15T10:30:00Z",
      "bodyPreview": "Just a reminder about our meeting..."
    }
  ]
}
```

**Documentation**: https://learn.microsoft.com/en-us/graph/api/user-list-messages

---

## Official Documentation References

### Core OAuth & Authentication

1. **Microsoft Entra ID OAuth 2.0 Authorization Code Flow**
   https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow

2. **Scopes and Permissions in Microsoft Identity Platform**
   https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc

3. **Microsoft Graph Permissions Overview**
   https://learn.microsoft.com/en-us/graph/permissions-overview

4. **Microsoft Graph Permissions Reference (Complete List)**
   https://learn.microsoft.com/en-us/graph/permissions-reference

### API-Specific Documentation

5. **Send Mail API**
   https://learn.microsoft.com/en-us/graph/api/user-sendmail

6. **List Messages API**
   https://learn.microsoft.com/en-us/graph/api/user-list-messages

7. **List Contacts API**
   https://learn.microsoft.com/en-us/graph/api/user-list-contacts

8. **Get Contact API**
   https://learn.microsoft.com/en-us/graph/api/contact-get

### Additional Resources

9. **Graph Permissions Explorer** (Third-party tool)
   https://graphpermissions.merill.net/

10. **Authentication and Authorization Basics**
    https://learn.microsoft.com/en-us/graph/auth/auth-concepts

---

## Implementation Details

### Controller Structure

**File**: `app/controllers/aven/oauth/entra_id_controller.rb`

**Inherits From**: `Aven::Oauth::BaseController`

**Implemented Methods**:

- `authorization_url(state)`: Builds the Microsoft authorization URL
- `exchange_code_for_token(code)`: Exchanges authorization code for access token
- `fetch_user_info(access_token)`: Retrieves user information from Microsoft Graph

**Helper Methods**:

- `callback_url`: Generates the OAuth callback URL
- `oauth_config`: Retrieves Entra ID configuration
- `tenant_id`: Returns the configured tenant ID (default: "common")
- `entra_authorization_url`: Microsoft authorization endpoint
- `entra_token_url`: Microsoft token endpoint
- `entra_userinfo_url`: Microsoft Graph user info endpoint

### Routes

**File**: `config/routes.rb:30-32`

```ruby
# Microsoft Entra ID OAuth
get "entra_id", to: "entra_id#create", as: :entra_id
get "entra_id/callback", to: "entra_id#callback", as: :entra_id_callback
```

**Available Routes**:

- `GET /oauth/entra_id` → Initiates OAuth flow
- `GET /oauth/entra_id/callback` → Handles OAuth callback

**Named Routes**:

- `oauth_entra_id_path` → `/oauth/entra_id`
- `oauth_entra_id_callback_path` → `/oauth/entra_id/callback`

---

## Security Considerations

### State Parameter

The implementation uses a secure random state token to prevent CSRF attacks:

```ruby
state = SecureRandom.hex(16)
session[:oauth_state] = state
```

The state is validated in the callback to ensure the response matches the request.

### Token Storage

Access tokens are stored in the `Aven::User` model:

```ruby
user.access_token = token_data[:access_token]
```

**Security Recommendations**:

1. Encrypt the `access_token` column in the database
2. Implement token refresh logic (access tokens expire)
3. Store `refresh_token` separately for long-term access
4. Use HTTPS for all OAuth endpoints

### HTTPS Requirement

OAuth 2.0 requires HTTPS for security. The implementation includes SSL verification:

```ruby
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
```

**Production**: Always use proper SSL certificates.

---

## Troubleshooting

### Common Issues

#### 1. "Invalid redirect_uri"

**Cause**: Redirect URI mismatch between your app and Azure configuration.

**Solution**: Ensure the redirect URI in Azure matches exactly:

```
https://yourdomain.com/oauth/entra_id/callback
```

#### 2. "AADSTS65001: The user or administrator has not consented"

**Cause**: User hasn't consented to the requested permissions.

**Solution**:

- Have admin grant consent in Azure portal
- Or adjust scopes to user-consentable permissions only

#### 3. "ErrorAccessDenied" when calling Graph API

**Cause**: Missing permissions or token scope mismatch.

**Solution**:

1. Verify permissions are added in Azure portal
2. Check the scope parameter includes all needed permissions
3. Request a new token after adding permissions

#### 4. "Invalid client secret"

**Cause**: Client secret expired or incorrect.

**Solution**:

1. Generate a new client secret in Azure portal
2. Update `ENTRA_ID_CLIENT_SECRET` environment variable
3. Note: Secrets expire (check expiration date)

### Debug Mode

In development, detailed errors are shown:

```ruby
error_message = if Rails.env.production?
  "Authentication failed. Please try again."
else
  "#{e.message}"
end
```

Check Rails logs for full error details.

---

## Token Refresh (Future Enhancement)

Currently, the implementation stores only the access token. For long-term access, implement refresh token logic:

```ruby
def refresh_access_token(refresh_token)
  params = {
    client_id: oauth_config[:client_id],
    client_secret: oauth_config[:client_secret],
    refresh_token: refresh_token,
    grant_type: "refresh_token"
  }

  oauth_request(URI(entra_token_url), params)
end
```

Store the `refresh_token` from the initial token response and use it to obtain new access tokens when they expire (typically after 1 hour).

---

## Testing

### Manual Testing

1. Navigate to: `http://localhost:3000/oauth/entra_id`
2. Sign in with a Microsoft account
3. Grant permissions when prompted
4. Verify redirect back to your application
5. Check user record has `access_token` populated

### Test Accounts

For development, create test users in your Azure AD tenant:

- Go to **Azure Active Directory** > **Users**
- Create test users with various permission levels

### GraphQL Explorer

Test Graph API calls using Microsoft's Graph Explorer:
https://developer.microsoft.com/en-us/graph/graph-explorer

---

## Additional Features to Consider

### 1. Profile Picture Support

Microsoft Graph supports retrieving user photos:

```ruby
GET https://graph.microsoft.com/v1.0/me/photo/$value
Authorization: Bearer {access_token}
```

Update `fetch_user_info` to include picture URL.

### 2. Offline Access

Add `offline_access` scope to receive refresh tokens:

```ruby
DEFAULT_SCOPE = "openid email profile offline_access User.Read Contacts.Read Mail.Send Mail.Read"
```

### 3. Calendar Access

Add calendar permissions:

- `Calendars.Read`: Read user's calendar
- `Calendars.ReadWrite`: Full calendar access

### 4. OneDrive Access

Add file storage permissions:

- `Files.Read`: Read user's files
- `Files.ReadWrite`: Full file access

---

## Version History

- **v1.0** (2025-10-15): Initial implementation with authentication, contacts, and email support

---

## Support & Resources

- **Microsoft Graph API Documentation**: https://learn.microsoft.com/en-us/graph/
- **Azure Portal**: https://portal.azure.com
- **Microsoft Q&A**: https://learn.microsoft.com/en-us/answers/
- **Stack Overflow**: Tag with `microsoft-graph` and `azure-active-directory`

---

**Last Updated**: October 15, 2025
**Maintained By**: Aven Development Team
