# frozen_string_literal: true

namespace :aven do
  namespace :system_users do
    desc "Create test system user and seed test data (workspace, users, features, contacts)"
    task create_test: :environment do
      puts "🌱 Seeding test data..."
      puts ""

      # 1. Create system user
      puts "1️⃣  Creating system user..."
      system_user = Aven::SystemUser.find_or_initialize_by(email: "admin@test.com")
      unless system_user.persisted?
        system_user.password = "password123456"
        system_user.password_confirmation = "password123456"
      end

      if system_user.save
        puts "   ✅ System user: admin@test.com / password123456"
      else
        puts "   ❌ Failed: #{system_user.errors.full_messages.join(', ')}"
      end
      puts ""

      # 2. Create first user (needed for workspace created_by)
      puts "2️⃣  Creating first user..."
      first_user = Aven::User.find_or_initialize_by(email: "user1@test.com", auth_tenant: "localhost")
      unless first_user.persisted?
        first_user.password = "password123456"
        first_user.password_confirmation = "password123456"
        first_user.admin = false
      end

      if first_user.save
        puts "   ✅ User: #{first_user.email}"
      else
        puts "   ❌ Failed: #{first_user.errors.full_messages.join(', ')}"
        exit 1
      end
      puts ""

      # 3. Create workspace
      puts "3️⃣  Creating test workspace..."
      workspace = Aven::Workspace.find_or_initialize_by(slug: "test-workspace")
      unless workspace.persisted?
        workspace.label = "Test Workspace"
        workspace.description = "A test workspace for development"
        workspace.created_by = first_user
        workspace.onboarding_state = "completed"
      end

      if workspace.save
        puts "   ✅ Workspace: #{workspace.label} (#{workspace.slug})"
      else
        puts "   ❌ Failed: #{workspace.errors.full_messages.join(', ')}"
      end
      puts ""

      # 4. Add first user to workspace
      Aven::WorkspaceUser.find_or_create_by!(workspace:, user: first_user)

      # 5. Create additional users
      puts "4️⃣  Creating additional test users..."
      users = [
        { email: "user2@test.com", admin: false },
        { email: "admin.user@test.com", admin: true }
      ]

      users.each do |user_data|
        user = Aven::User.find_or_initialize_by(email: user_data[:email], auth_tenant: "localhost")
        unless user.persisted?
          user.password = "password123456"
          user.password_confirmation = "password123456"
          user.admin = user_data[:admin]
        end

        if user.save
          # Add to workspace
          Aven::WorkspaceUser.find_or_create_by!(workspace:, user:)
          puts "   ✅ User: #{user.email} (admin: #{user.admin})"
        else
          puts "   ❌ Failed: #{user.errors.full_messages.join(', ')}"
        end
      end
      puts ""

      # 6. Create features
      puts "6️⃣  Creating features..."
      features_data = [
        { name: "Contacts", slug: "contacts", feature_type: "core", auto_activate: true },
        { name: "RIB Checks", slug: "rib_checks", feature_type: "producer", auto_activate: true },
        { name: "Invitations", slug: "invites", feature_type: "core", auto_activate: true },
        { name: "Members", slug: "members", feature_type: "core", auto_activate: true },
        { name: "Electronic Signatures", slug: "yousign", feature_type: "producer", auto_activate: false },
        { name: "Profile", slug: "profile", feature_type: "core", auto_activate: true },
        { name: "Search", slug: "search", feature_type: "core", auto_activate: true }
      ]

      features_data.each do |feature_data|
        feature = Aven::Feature.find_or_initialize_by(slug: feature_data[:slug])
        feature.assign_attributes(
          name: feature_data[:name],
          feature_type: feature_data[:feature_type],
          auto_activate: feature_data[:auto_activate],
          editorial_title: "#{feature_data[:name]} (Test)",
          description: "Test feature for #{feature_data[:name]}"
        )

        if feature.save
          puts "   ✅ Feature: #{feature.name} (#{feature.slug})"
        else
          puts "   ❌ Failed: #{feature.errors.full_messages.join(', ')}"
        end
      end
      puts ""

      # 7. Create item schema for contacts (if needed)
      puts "7️⃣  Creating contact schema..."
      contact_schema = Aven::ItemSchema.find_or_initialize_by(workspace:, slug: "contact")
      unless contact_schema.persisted?
        contact_schema.assign_attributes(
          schema: {
            type: "object",
            properties: {
              display_name: { type: "string" },
              first_name: { type: "string" },
              last_name: { type: "string" },
              email: { type: "string" },
              company: { type: "string" },
              job_title: { type: "string" },
              gender: { type: "string" }
            }
          },
          fields: {},
          embeds: {},
          links: {}
        )
      end

      if contact_schema.save
        puts "   ✅ Contact schema created"
      else
        puts "   ⚠️  Contact schema skipped (#{contact_schema.errors.full_messages.join(', ')})"
      end
      puts ""

      # 8. Create contacts (Items with contact schema)
      puts "8️⃣  Creating test contacts..."
      if Aven::ItemSchema.exists?(workspace:, slug: "contact")
        contacts_data = [
          {
            display_name: "John Doe",
            first_name: "John",
            last_name: "Doe",
            email: "john.doe@example.com",
            company: "Acme Corp",
            job_title: "CEO",
            gender: "male"
          },
          {
            display_name: "Jane Smith",
            first_name: "Jane",
            last_name: "Smith",
            email: "jane.smith@example.com",
            company: "Tech Inc",
            job_title: "CTO",
            gender: "female"
          },
          {
            display_name: "Bob Johnson",
            first_name: "Bob",
            last_name: "Johnson",
            email: "bob.johnson@example.com",
            company: "StartUp LLC",
            job_title: "Founder",
            gender: "male"
          }
        ]

        contacts_data.each do |contact_data|
          contact = Aven::Item.where(workspace_id: workspace.id, schema_slug: "contact")
                              .where("data @> ?", contact_data.to_json)
                              .first_or_initialize
          unless contact.persisted?
            contact.workspace_id = workspace.id
            contact.data = contact_data
            contact.created_by_id = first_user.id
          end

          if contact.save
            puts "   ✅ Contact: #{contact_data[:display_name]}"
          else
            puts "   ❌ Failed: #{contact.errors.full_messages.join(', ')}"
          end
        end
      else
        puts "   ⚠️  Skipping contacts (schema not found)"
      end
      puts ""

      # 9. Create item recipients
      puts "9️⃣  Creating item recipients..."
      first_contact = Aven::Item.by_schema("contact").first
      second_contact = Aven::Item.by_schema("contact").second

      if first_contact && second_contact
        # Create rib_check schema if needed
        rib_schema = Aven::ItemSchema.find_or_initialize_by(workspace:, slug: "rib_check")
        unless rib_schema.persisted?
          rib_schema.assign_attributes(
            schema: {
              type: "object",
              properties: {
                subject: { type: "string" },
                status: { type: "string" }
              }
            },
            fields: {},
            embeds: {},
            links: {}
          )
          rib_schema.save!
          puts "   ✅ RIB check schema created"
        end

        # Create a source item (e.g., a RIB check request)
        # Use a unique identifier in the data to make it idempotent
        source_item_data = {
          subject: "Bank details verification",
          status: "pending",
          _seed_id: "test_rib_check_1"
        }

        source_item = Aven::Item.where(
          workspace:,
          schema_slug: "rib_check"
        ).where("data @> ?", { _seed_id: "test_rib_check_1" }.to_json).first

        unless source_item
          puts "   → Creating RIB check item (workspace_id: #{workspace.id}, created_by_id: #{first_user.id})"
          source_item = Aven::Item.create!(
            workspace_id: workspace.id,
            schema_slug: "rib_check",
            data: source_item_data,
            created_by_id: first_user.id
          )
        end

        # Add recipients
        Aven::ItemRecipient.find_or_create_by!(
          source_item:,
          target_item: first_contact,
          workspace_id: workspace.id,
          created_by_id: first_user.id
        )

        Aven::ItemRecipient.find_or_create_by!(
          source_item:,
          target_item: second_contact,
          workspace_id: workspace.id,
          created_by_id: first_user.id
        )

        puts "   ✅ Created recipients for source item"
      else
        raise "Cannot create recipients: contacts not found"
      end
      puts ""

      # 🔟 Create invites
      puts "🔟 Creating test invites..."
      invites_data = [
        { email: "invited1@test.com", type: "join_workspace", status: "pending" },
        { email: "invited2@test.com", type: "fulfillment", status: "accepted" },
        { email: "invited3@test.com", type: "join_workspace_fulfillment", status: "pending" }
      ]

      invites_data.each do |invite_data|
        invite = Aven::Invite.find_or_initialize_by(
          workspace:,
          invitee_email: invite_data[:email]
        )
        unless invite.persisted?
          invite.assign_attributes(
            invite_type: invite_data[:type],
            status: invite_data[:status],
            auth_link_hash: SecureRandom.hex(32)
          )
        end

        if invite.save
          puts "   ✅ Invite: #{invite_data[:email]} (#{invite_data[:type]})"
        else
          puts "   ❌ Failed: #{invite.errors.full_messages.join(', ')}"
        end
      end
      puts ""

      # Summary
      puts "=" * 60
      puts "✨ Test data seeded successfully!"
      puts "=" * 60
      puts ""
      puts "System Admin Login:"
      puts "  URL: /aven/system"
      puts "  Email: admin@test.com"
      puts "  Password: password123456"
      puts ""
      puts "Regular User Login:"
      puts "  URL: /aven/auth/sign_in"
      puts "  Email: user1@test.com"
      puts "  Password: password123456"
      puts ""
      puts "Summary:"
      puts "  - #{Aven::SystemUser.count} system users"
      puts "  - #{Aven::Workspace.count} workspaces"
      puts "  - #{Aven::User.count} users"
      puts "  - #{Aven::Feature.count} features"
      puts "  - #{Aven::ItemSchema.count} item schemas"
      puts "  - #{Aven::Item.where(schema_slug: 'contact').count} contacts"
      puts "  - #{Aven::ItemRecipient.count} item recipients"
      puts "  - #{Aven::Invite.count} invites"
      puts ""
    end

    desc "Create a system user with custom email and password"
    task :create, [:email, :password] => :environment do |t, args|
      unless args.email && args.password
        puts "Usage: rake aven:system_users:create[email@example.com,password123]"
        next
      end

      user = Aven::SystemUser.find_or_initialize_by(email: args.email)
      user.password = args.password
      user.password_confirmation = args.password

      if user.save
        action = user.previously_new_record? ? "Created" : "Updated"
        puts "#{action} system user: #{user.email}"
      else
        puts "Failed to create system user: #{user.errors.full_messages.join(', ')}"
      end
    end
  end
end
