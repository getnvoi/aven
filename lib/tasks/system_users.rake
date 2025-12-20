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
      system_user.password = "password"
      system_user.password_confirmation = "password"

      if system_user.save
        puts "   ✅ System user: admin@test.com / password"
      else
        puts "   ❌ Failed: #{system_user.errors.full_messages.join(', ')}"
      end
      puts ""

      # 2. Create workspace
      puts "2️⃣  Creating test workspace..."
      workspace = Aven::Workspace.find_or_initialize_by(slug: "test-workspace")
      workspace.label = "Test Workspace"
      workspace.description = "A test workspace for development"

      if workspace.save
        puts "   ✅ Workspace: #{workspace.label} (#{workspace.slug})"
      else
        puts "   ❌ Failed: #{workspace.errors.full_messages.join(', ')}"
      end
      puts ""

      # 3. Create regular users
      puts "3️⃣  Creating test users..."
      users = [
        { email: "user1@test.com", admin: false },
        { email: "user2@test.com", admin: false },
        { email: "admin.user@test.com", admin: true }
      ]

      users.each do |user_data|
        user = Aven::User.find_or_initialize_by(email: user_data[:email])
        user.password = "password"
        user.admin = user_data[:admin]

        if user.save
          # Add to workspace
          Aven::WorkspaceUser.find_or_create_by!(workspace:, user:)
          puts "   ✅ User: #{user.email} (admin: #{user.admin})"
        else
          puts "   ❌ Failed: #{user.errors.full_messages.join(', ')}"
        end
      end
      puts ""

      # 4. Create features
      puts "4️⃣  Creating features..."
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

      # 5. Create contacts (Items with contact schema)
      puts "5️⃣  Creating test contacts..."
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

      first_user = Aven::User.find_by(email: "user1@test.com")

      contacts_data.each do |contact_data|
        contact = Aven::Item.find_or_initialize_by(
          workspace:,
          schema_slug: "contact",
          data: contact_data
        )
        contact.created_by = first_user

        if contact.save
          puts "   ✅ Contact: #{contact_data[:display_name]}"
        else
          puts "   ❌ Failed: #{contact.errors.full_messages.join(', ')}"
        end
      end
      puts ""

      # 6. Create item recipients
      puts "6️⃣  Creating item recipients..."
      first_contact = Aven::Item.by_schema("contact").first
      second_contact = Aven::Item.by_schema("contact").second

      if first_contact && second_contact
        # Create a source item (e.g., a RIB check request)
        source_item = Aven::Item.find_or_create_by!(
          workspace:,
          schema_slug: "rib_check",
          data: {
            subject: "Bank details verification",
            status: "pending"
          },
          created_by: first_user
        )

        # Add recipients
        recipient1 = Aven::ItemRecipient.find_or_create_by!(
          source_item:,
          target_item: first_contact
        )

        recipient2 = Aven::ItemRecipient.find_or_create_by!(
          source_item:,
          target_item: second_contact
        )

        puts "   ✅ Created recipients for source item"
      end
      puts ""

      # 7. Create invites
      puts "7️⃣  Creating test invites..."
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
        invite.assign_attributes(
          invite_type: invite_data[:type],
          status: invite_data[:status],
          auth_link_hash: SecureRandom.hex(32)
        )

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
      puts "  URL: /system/login"
      puts "  Email: admin@test.com"
      puts "  Password: password"
      puts ""
      puts "Regular User Login:"
      puts "  URL: /login (or your main auth endpoint)"
      puts "  Email: user1@test.com"
      puts "  Password: password"
      puts ""
      puts "Summary:"
      puts "  - #{Aven::SystemUser.count} system users"
      puts "  - #{Aven::Workspace.count} workspaces"
      puts "  - #{Aven::User.count} users"
      puts "  - #{Aven::Feature.count} features"
      puts "  - #{Aven::Item.by_schema('contact').count} contacts"
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
