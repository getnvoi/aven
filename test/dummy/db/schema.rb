# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_20_172000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "aven_article_attachments", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "position"], name: "index_aven_article_attachments_on_article_id_and_position"
    t.index ["article_id"], name: "index_aven_article_attachments_on_article_id"
  end

  create_table "aven_article_relationships", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.bigint "related_article_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "position"], name: "index_aven_article_relationships_on_article_id_and_position"
    t.index ["article_id", "related_article_id"], name: "idx_article_relationships_unique", unique: true
    t.index ["article_id"], name: "index_aven_article_relationships_on_article_id"
    t.index ["related_article_id"], name: "index_aven_article_relationships_on_related_article_id"
  end

  create_table "aven_articles", force: :cascade do |t|
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "intro"
    t.datetime "published_at"
    t.string "slug"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["author_id"], name: "index_aven_articles_on_author_id"
    t.index ["published_at"], name: "index_aven_articles_on_published_at"
    t.index ["workspace_id", "slug"], name: "index_aven_articles_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_aven_articles_on_workspace_id"
  end

  create_table "aven_chat_messages", force: :cascade do |t|
    t.datetime "completed_at"
    t.text "content"
    t.decimal "cost_usd", precision: 10, scale: 6, default: "0.0"
    t.datetime "created_at", null: false
    t.integer "input_tokens", default: 0
    t.string "model"
    t.integer "output_tokens", default: 0
    t.bigint "parent_id"
    t.string "role", null: false
    t.datetime "started_at"
    t.string "status", default: "pending"
    t.bigint "thread_id", null: false
    t.jsonb "tool_call"
    t.integer "total_tokens", default: 0
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_aven_chat_messages_on_parent_id"
    t.index ["role"], name: "index_aven_chat_messages_on_role"
    t.index ["status"], name: "index_aven_chat_messages_on_status"
    t.index ["thread_id", "created_at"], name: "index_aven_chat_messages_on_thread_id_and_created_at"
    t.index ["thread_id"], name: "index_aven_chat_messages_on_thread_id"
  end

  create_table "aven_chat_threads", force: :cascade do |t|
    t.text "context_markdown"
    t.datetime "created_at", null: false
    t.jsonb "documents"
    t.string "title"
    t.jsonb "tools"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["created_at"], name: "index_aven_chat_threads_on_created_at"
    t.index ["user_id"], name: "index_aven_chat_threads_on_user_id"
    t.index ["workspace_id", "user_id"], name: "index_aven_chat_threads_on_workspace_id_and_user_id"
    t.index ["workspace_id"], name: "index_aven_chat_threads_on_workspace_id"
  end

  create_table "aven_feature_tool_usages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.bigint "feature_tool_id", null: false
    t.integer "http_status_code"
    t.jsonb "metadata", default: {}
    t.string "status", default: "success", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["created_at"], name: "idx_aven_feature_tool_usages_time"
    t.index ["feature_tool_id", "created_at"], name: "idx_aven_feature_tool_usages_tool_time"
    t.index ["feature_tool_id"], name: "index_aven_feature_tool_usages_on_feature_tool_id"
    t.index ["user_id", "created_at"], name: "idx_aven_feature_tool_usages_user_time"
    t.index ["user_id"], name: "index_aven_feature_tool_usages_on_user_id"
    t.index ["workspace_id", "created_at"], name: "idx_aven_feature_tool_usages_workspace_time"
    t.index ["workspace_id", "feature_tool_id", "created_at"], name: "idx_aven_feature_tool_usages_billing"
    t.index ["workspace_id"], name: "index_aven_feature_tool_usages_on_workspace_id"
  end

  create_table "aven_feature_tools", force: :cascade do |t|
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.bigint "feature_id", null: false
    t.bigint "schema_id"
    t.string "slug", null: false
    t.string "title", null: false
    t.string "tool_type"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_aven_feature_tools_on_deleted_at"
    t.index ["feature_id"], name: "index_aven_feature_tools_on_feature_id"
    t.index ["schema_id"], name: "index_aven_feature_tools_on_schema_id"
    t.index ["slug", "feature_id"], name: "index_aven_feature_tools_on_slug_and_feature_id", unique: true
  end

  create_table "aven_feature_workspace_users", force: :cascade do |t|
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.bigint "feature_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["feature_id"], name: "index_aven_feature_workspace_users_on_feature_id"
    t.index ["user_id"], name: "index_aven_feature_workspace_users_on_user_id"
    t.index ["workspace_id", "user_id", "feature_id"], name: "idx_aven_feature_workspace_users_unique", unique: true
    t.index ["workspace_id"], name: "index_aven_feature_workspace_users_on_workspace_id"
  end

  create_table "aven_features", force: :cascade do |t|
    t.boolean "auto_activate", default: false, null: false
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.text "editorial_body"
    t.text "editorial_description"
    t.string "editorial_title"
    t.string "feature_type", default: "boolean", null: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_aven_features_on_deleted_at"
    t.index ["feature_type"], name: "index_aven_features_on_feature_type"
    t.index ["slug"], name: "index_aven_features_on_slug", unique: true
  end

  create_table "aven_import_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.bigint "import_id", null: false
    t.datetime "updated_at", null: false
    t.index ["data"], name: "index_aven_import_entries_on_data", using: :gin
    t.index ["import_id"], name: "index_aven_import_entries_on_import_id"
  end

  create_table "aven_import_item_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entry_id", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id", "item_id"], name: "index_aven_import_item_links_on_entry_id_and_item_id", unique: true
    t.index ["entry_id"], name: "index_aven_import_item_links_on_entry_id"
    t.index ["item_id"], name: "index_aven_import_item_links_on_item_id"
  end

  create_table "aven_imports", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.jsonb "errors_log", default: []
    t.integer "imported_count", default: 0
    t.integer "processed_count", default: 0
    t.integer "skipped_count", default: 0
    t.string "source", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.integer "total_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["source"], name: "index_aven_imports_on_source"
    t.index ["status"], name: "index_aven_imports_on_status"
    t.index ["workspace_id"], name: "index_aven_imports_on_workspace_id"
  end

  create_table "aven_invites", force: :cascade do |t|
    t.string "auth_link_hash", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "invite_type", null: false
    t.string "invitee_email", null: false
    t.string "invitee_phone"
    t.bigint "item_recipient_id"
    t.datetime "sent_at"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["auth_link_hash"], name: "index_aven_invites_on_auth_link_hash", unique: true
    t.index ["invite_type"], name: "index_aven_invites_on_invite_type"
    t.index ["invitee_email"], name: "index_aven_invites_on_invitee_email"
    t.index ["item_recipient_id"], name: "index_aven_invites_on_item_recipient_id"
    t.index ["workspace_id"], name: "index_aven_invites_on_workspace_id"
  end

  create_table "aven_item_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "item_id", null: false
    t.string "label"
    t.jsonb "metadata", default: {}
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id"
    t.bigint "workspace_id", null: false
    t.index ["item_id"], name: "index_aven_item_documents_on_item_id"
    t.index ["metadata"], name: "index_aven_item_documents_on_metadata", using: :gin
    t.index ["uploaded_by_id"], name: "index_aven_item_documents_on_uploaded_by_id"
    t.index ["workspace_id"], name: "index_aven_item_documents_on_workspace_id"
  end

  create_table "aven_item_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "position", default: 0
    t.string "relation", null: false
    t.bigint "source_id", null: false
    t.bigint "target_id", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id", "relation"], name: "index_aven_item_links_on_source_id_and_relation"
    t.index ["source_id", "target_id", "relation"], name: "index_aven_item_links_on_source_id_and_target_id_and_relation", unique: true
    t.index ["source_id"], name: "index_aven_item_links_on_source_id"
    t.index ["target_id", "relation"], name: "index_aven_item_links_on_target_id_and_relation"
    t.index ["target_id"], name: "index_aven_item_links_on_target_id"
  end

  create_table "aven_item_recipients", force: :cascade do |t|
    t.boolean "allow_delegate", default: false
    t.datetime "completed_at"
    t.string "completion_state", default: "pending"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "delegated_from_recipient_id"
    t.text "description"
    t.bigint "invitee_id"
    t.string "label"
    t.datetime "otp_sent_at"
    t.integer "position", default: 0
    t.string "security_level", default: "none"
    t.bigint "source_item_id"
    t.bigint "target_item_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "workspace_id", null: false
    t.index ["completion_state"], name: "index_aven_item_recipients_on_completion_state"
    t.index ["created_by_id"], name: "index_aven_item_recipients_on_created_by_id"
    t.index ["delegated_from_recipient_id"], name: "index_aven_item_recipients_on_delegated_from_recipient_id"
    t.index ["invitee_id"], name: "index_aven_item_recipients_on_invitee_id"
    t.index ["source_item_id", "target_item_id"], name: "index_item_recipients_source_target"
    t.index ["source_item_id"], name: "index_aven_item_recipients_on_source_item_id"
    t.index ["target_item_id"], name: "index_aven_item_recipients_on_target_item_id"
    t.index ["user_id"], name: "index_aven_item_recipients_on_user_id"
    t.index ["workspace_id"], name: "index_aven_item_recipients_on_workspace_id"
  end

  create_table "aven_item_schemas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "embeds", default: {}, null: false
    t.jsonb "fields", default: {}, null: false
    t.jsonb "links", default: {}, null: false
    t.jsonb "schema", default: {}, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["slug"], name: "index_aven_item_schemas_on_slug"
    t.index ["workspace_id", "slug"], name: "index_aven_item_schemas_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_aven_item_schemas_on_workspace_id"
  end

  create_table "aven_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.jsonb "data", default: {}, null: false
    t.datetime "deleted_at"
    t.string "schema_slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "workspace_id", null: false
    t.index ["created_by_id"], name: "index_aven_items_on_created_by_id"
    t.index ["data"], name: "index_aven_items_on_data", using: :gin
    t.index ["deleted_at"], name: "index_aven_items_on_deleted_at"
    t.index ["schema_slug"], name: "index_aven_items_on_schema_slug"
    t.index ["updated_by_id"], name: "index_aven_items_on_updated_by_id"
    t.index ["workspace_id"], name: "index_aven_items_on_workspace_id"
  end

  create_table "aven_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "level", default: "info", null: false
    t.bigint "loggable_id", null: false
    t.string "loggable_type", null: false
    t.text "message", null: false
    t.jsonb "metadata"
    t.string "run_id"
    t.string "state"
    t.string "state_machine"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["created_at"], name: "index_aven_logs_on_created_at"
    t.index ["level"], name: "index_aven_logs_on_level"
    t.index ["loggable_type", "loggable_id", "run_id", "state", "created_at"], name: "idx_aven_logs_on_loggable_run_state_created_at"
    t.index ["loggable_type", "loggable_id"], name: "index_aven_logs_on_loggable"
    t.index ["workspace_id"], name: "index_aven_logs_on_workspace_id"
  end

  create_table "aven_magic_links", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "purpose", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["code"], name: "index_aven_magic_links_on_code", unique: true
    t.index ["expires_at"], name: "index_aven_magic_links_on_expires_at"
    t.index ["user_id"], name: "index_aven_magic_links_on_user_id"
  end

  create_table "aven_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["updated_at"], name: "index_aven_sessions_on_updated_at"
    t.index ["user_id"], name: "index_aven_sessions_on_user_id"
  end

  create_table "aven_system_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_aven_system_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_aven_system_users_on_reset_password_token", unique: true
  end

  create_table "aven_users", force: :cascade do |t|
    t.string "access_token"
    t.boolean "admin", default: false, null: false
    t.string "auth_tenant"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "password_digest"
    t.datetime "remember_created_at"
    t.string "remote_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email", "auth_tenant"], name: "index_aven_users_on_email_and_auth_tenant", unique: true
    t.index ["reset_password_token"], name: "index_aven_users_on_reset_password_token", unique: true
  end

  create_table "aven_workspace_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "label", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id"
    t.index ["workspace_id", "label"], name: "idx_aven_workspace_roles_on_ws_label", unique: true
    t.index ["workspace_id"], name: "index_aven_workspace_roles_on_workspace_id"
  end

  create_table "aven_workspace_user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_role_id"
    t.bigint "workspace_user_id"
    t.index ["workspace_role_id", "workspace_user_id"], name: "idx_aven_ws_user_roles_on_role_user", unique: true
    t.index ["workspace_role_id"], name: "index_aven_workspace_user_roles_on_workspace_role_id"
    t.index ["workspace_user_id"], name: "index_aven_workspace_user_roles_on_workspace_user_id"
  end

  create_table "aven_workspace_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id", "workspace_id"], name: "idx_aven_workspace_users_on_user_workspace", unique: true
    t.index ["user_id"], name: "index_aven_workspace_users_on_user_id"
    t.index ["workspace_id"], name: "index_aven_workspace_users_on_workspace_id"
  end

  create_table "aven_workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.string "domain"
    t.string "label"
    t.string "onboarding_state", default: "pending"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_aven_workspaces_on_created_by_id"
    t.index ["slug"], name: "index_aven_workspaces_on_slug", unique: true
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "searchable_id"
    t.string "searchable_type"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id"
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
    t.index ["workspace_id"], name: "index_pg_search_documents_on_workspace_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.bigint "tag_id"
    t.bigint "taggable_id"
    t.string "taggable_type"
    t.bigint "tagger_id"
    t.string "tagger_type"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "taggings_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "test_projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["workspace_id"], name: "index_test_projects_on_workspace_id"
  end

  create_table "test_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id"
    t.index ["workspace_id"], name: "index_test_resources_on_workspace_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aven_article_attachments", "aven_articles", column: "article_id"
  add_foreign_key "aven_article_relationships", "aven_articles", column: "article_id"
  add_foreign_key "aven_article_relationships", "aven_articles", column: "related_article_id"
  add_foreign_key "aven_articles", "aven_users", column: "author_id"
  add_foreign_key "aven_articles", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_chat_messages", "aven_chat_messages", column: "parent_id"
  add_foreign_key "aven_chat_messages", "aven_chat_threads", column: "thread_id"
  add_foreign_key "aven_chat_threads", "aven_users", column: "user_id"
  add_foreign_key "aven_chat_threads", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_feature_tool_usages", "aven_feature_tools", column: "feature_tool_id"
  add_foreign_key "aven_feature_tool_usages", "aven_users", column: "user_id"
  add_foreign_key "aven_feature_tool_usages", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_feature_tools", "aven_features", column: "feature_id"
  add_foreign_key "aven_feature_workspace_users", "aven_features", column: "feature_id"
  add_foreign_key "aven_feature_workspace_users", "aven_users", column: "user_id"
  add_foreign_key "aven_feature_workspace_users", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_import_entries", "aven_imports", column: "import_id"
  add_foreign_key "aven_import_item_links", "aven_import_entries", column: "entry_id"
  add_foreign_key "aven_import_item_links", "aven_items", column: "item_id"
  add_foreign_key "aven_imports", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_invites", "aven_item_recipients", column: "item_recipient_id"
  add_foreign_key "aven_invites", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_item_documents", "aven_items", column: "item_id"
  add_foreign_key "aven_item_documents", "aven_users", column: "uploaded_by_id"
  add_foreign_key "aven_item_documents", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_item_links", "aven_items", column: "source_id"
  add_foreign_key "aven_item_links", "aven_items", column: "target_id"
  add_foreign_key "aven_item_recipients", "aven_item_recipients", column: "delegated_from_recipient_id"
  add_foreign_key "aven_item_recipients", "aven_items", column: "source_item_id"
  add_foreign_key "aven_item_recipients", "aven_items", column: "target_item_id"
  add_foreign_key "aven_item_recipients", "aven_users", column: "created_by_id"
  add_foreign_key "aven_item_recipients", "aven_users", column: "invitee_id"
  add_foreign_key "aven_item_recipients", "aven_users", column: "user_id"
  add_foreign_key "aven_item_recipients", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_item_schemas", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_items", "aven_users", column: "created_by_id"
  add_foreign_key "aven_items", "aven_users", column: "updated_by_id"
  add_foreign_key "aven_items", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_logs", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_magic_links", "aven_users", column: "user_id"
  add_foreign_key "aven_sessions", "aven_users", column: "user_id"
  add_foreign_key "aven_workspace_roles", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_workspace_user_roles", "aven_workspace_roles", column: "workspace_role_id"
  add_foreign_key "aven_workspace_user_roles", "aven_workspace_users", column: "workspace_user_id"
  add_foreign_key "aven_workspace_users", "aven_users", column: "user_id"
  add_foreign_key "aven_workspace_users", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_workspaces", "aven_users", column: "created_by_id"
  add_foreign_key "pg_search_documents", "aven_workspaces", column: "workspace_id"
  add_foreign_key "taggings", "tags"
  add_foreign_key "test_projects", "aven_workspaces", column: "workspace_id"
  add_foreign_key "test_resources", "aven_workspaces", column: "workspace_id"
end
