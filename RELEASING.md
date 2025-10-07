# Releasing Sqema

This document describes how to release a new version of Sqema to RubyGems.

## Setup (One-time)

1. **Get your RubyGems API key:**
   - Log in to [RubyGems.org](https://rubygems.org)
   - Go to your account settings → API Keys
   - Create a new API key with push permissions

2. **Add the API key to GitHub Secrets:**
   - Go to your GitHub repository settings
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `RUBYGEMS_API_KEY`
   - Value: Your RubyGems API key
   - Click "Add secret"

## Releasing a New Version

1. **Update the version:**
   ```bash
   # Edit lib/sqema/version.rb
   # Change VERSION = "0.1.0" to your new version
   ```

2. **Update the CHANGELOG:**
   ```bash
   # Edit CHANGELOG.md
   # Add a new section for your version with changes
   ```

3. **Commit your changes:**
   ```bash
   git add lib/sqema/version.rb CHANGELOG.md
   git commit -m "Bump version to X.Y.Z"
   git push
   ```

4. **Create and push a git tag:**
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

5. **Wait for the GitHub Action to complete:**
   - The release workflow will automatically:
     - Build the gem
     - Create a GitHub release with release notes
     - Publish the gem to RubyGems.org

6. **Verify the release:**
   - Check the [GitHub releases page](https://github.com/ben/sqema/releases)
   - Check [RubyGems.org](https://rubygems.org/gems/sqema)

## Troubleshooting

- If the release fails, check the GitHub Actions logs
- Ensure your RUBYGEMS_API_KEY secret is set correctly
- Verify that the version in `lib/sqema/version.rb` matches your git tag (without the 'v' prefix)
- Make sure you have MFA enabled on RubyGems (required by the gem configuration)
