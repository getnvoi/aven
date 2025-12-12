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

ActiveRecord::Schema[8.0].define(version: 2025_12_12_050626) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "aven_agentic_agent_documents", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "document_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "document_id"], name: "index_aven_agentic_agent_documents_on_agent_id_and_document_id", unique: true
    t.index ["agent_id"], name: "index_aven_agentic_agent_documents_on_agent_id"
    t.index ["document_id"], name: "index_aven_agentic_agent_documents_on_document_id"
  end

  create_table "aven_agentic_agent_tools", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "tool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "tool_id"], name: "index_aven_agentic_agent_tools_on_agent_id_and_tool_id", unique: true
    t.index ["agent_id"], name: "index_aven_agentic_agent_tools_on_agent_id"
    t.index ["tool_id"], name: "index_aven_agentic_agent_tools_on_tool_id"
  end

  create_table "aven_agentic_agents", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "label", null: false
    t.string "slug"
    t.text "system_prompt"
    t.text "user_facing_question"
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_aven_agentic_agents_on_enabled"
    t.index ["workspace_id", "slug"], name: "index_aven_agentic_agents_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_aven_agentic_agents_on_workspace_id"
  end

  create_table "aven_agentic_document_embeddings", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.integer "chunk_index", null: false
    t.text "content", null: false
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "chunk_index"], name: "idx_on_document_id_chunk_index_5fe199c056", unique: true
    t.index ["document_id"], name: "index_aven_agentic_document_embeddings_on_document_id"
  end

  create_table "aven_agentic_documents", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "filename", null: false
    t.string "content_type", null: false
    t.bigint "byte_size", null: false
    t.string "ocr_status", default: "pending", null: false
    t.text "ocr_content"
    t.string "embedding_status", default: "pending", null: false
    t.jsonb "metadata", default: {}
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type"], name: "index_aven_agentic_documents_on_content_type"
    t.index ["embedding_status"], name: "index_aven_agentic_documents_on_embedding_status"
    t.index ["ocr_status"], name: "index_aven_agentic_documents_on_ocr_status"
    t.index ["workspace_id"], name: "index_aven_agentic_documents_on_workspace_id"
  end

  create_table "aven_agentic_tool_parameters", force: :cascade do |t|
    t.bigint "tool_id", null: false
    t.string "name", null: false
    t.string "param_type", null: false
    t.text "description"
    t.text "default_description"
    t.boolean "required", default: false, null: false
    t.jsonb "constraints", default: {}
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_id", "name"], name: "index_aven_agentic_tool_parameters_on_tool_id_and_name", unique: true
    t.index ["tool_id", "position"], name: "index_aven_agentic_tool_parameters_on_tool_id_and_position"
    t.index ["tool_id"], name: "index_aven_agentic_tool_parameters_on_tool_id"
  end

  create_table "aven_agentic_tools", force: :cascade do |t|
    t.bigint "workspace_id"
    t.string "name", null: false
    t.string "class_name", null: false
    t.text "description"
    t.text "default_description"
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_aven_agentic_tools_on_enabled"
    t.index ["workspace_id", "class_name"], name: "index_aven_agentic_tools_on_workspace_id_and_class_name", unique: true
    t.index ["workspace_id", "name"], name: "index_aven_agentic_tools_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_aven_agentic_tools_on_workspace_id"
  end

  create_table "aven_chat_messages", force: :cascade do |t|
    t.bigint "thread_id", null: false
    t.bigint "parent_id"
    t.string "role", null: false
    t.string "status", default: "pending"
    t.text "content"
    t.string "model"
    t.integer "input_tokens", default: 0
    t.integer "output_tokens", default: 0
    t.integer "total_tokens", default: 0
    t.decimal "cost_usd", precision: 10, scale: 6, default: "0.0"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.jsonb "tool_call"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_aven_chat_messages_on_parent_id"
    t.index ["role"], name: "index_aven_chat_messages_on_role"
    t.index ["status"], name: "index_aven_chat_messages_on_status"
    t.index ["thread_id", "created_at"], name: "index_aven_chat_messages_on_thread_id_and_created_at"
    t.index ["thread_id"], name: "index_aven_chat_messages_on_thread_id"
  end

  create_table "aven_chat_threads", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "user_id", null: false
    t.bigint "agent_id"
    t.string "title"
    t.jsonb "tools"
    t.jsonb "documents"
    t.text "context_markdown"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_aven_chat_threads_on_agent_id"
    t.index ["created_at"], name: "index_aven_chat_threads_on_created_at"
    t.index ["user_id"], name: "index_aven_chat_threads_on_user_id"
    t.index ["workspace_id", "user_id"], name: "index_aven_chat_threads_on_workspace_id_and_user_id"
    t.index ["workspace_id"], name: "index_aven_chat_threads_on_workspace_id"
  end

  create_table "aven_item_links", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "target_id", null: false
    t.string "relation", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id", "relation"], name: "index_aven_item_links_on_source_id_and_relation"
    t.index ["source_id", "target_id", "relation"], name: "index_aven_item_links_on_source_id_and_target_id_and_relation", unique: true
    t.index ["source_id"], name: "index_aven_item_links_on_source_id"
    t.index ["target_id", "relation"], name: "index_aven_item_links_on_target_id_and_relation"
    t.index ["target_id"], name: "index_aven_item_links_on_target_id"
  end

  create_table "aven_item_schemas", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "slug", null: false
    t.jsonb "schema", default: {}, null: false
    t.jsonb "fields", default: {}, null: false
    t.jsonb "embeds", default: {}, null: false
    t.jsonb "links", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_aven_item_schemas_on_slug"
    t.index ["workspace_id", "slug"], name: "index_aven_item_schemas_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_aven_item_schemas_on_workspace_id"
  end

  create_table "aven_items", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "schema_slug", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data"], name: "index_aven_items_on_data", using: :gin
    t.index ["deleted_at"], name: "index_aven_items_on_deleted_at"
    t.index ["schema_slug"], name: "index_aven_items_on_schema_slug"
    t.index ["workspace_id"], name: "index_aven_items_on_workspace_id"
  end

  create_table "aven_logs", force: :cascade do |t|
    t.string "level", default: "info", null: false
    t.string "loggable_type", null: false
    t.bigint "loggable_id", null: false
    t.text "message", null: false
    t.jsonb "metadata"
    t.string "state"
    t.string "state_machine"
    t.string "run_id"
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_aven_logs_on_created_at"
    t.index ["level"], name: "index_aven_logs_on_level"
    t.index ["loggable_type", "loggable_id", "run_id", "state", "created_at"], name: "idx_aven_logs_on_loggable_run_state_created_at"
    t.index ["loggable_type", "loggable_id"], name: "index_aven_logs_on_loggable"
    t.index ["workspace_id"], name: "index_aven_logs_on_workspace_id"
  end

  create_table "aven_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "auth_tenant"
    t.string "remote_id"
    t.string "access_token"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email", "auth_tenant"], name: "index_aven_users_on_email_and_auth_tenant", unique: true
    t.index ["reset_password_token"], name: "index_aven_users_on_reset_password_token", unique: true
  end

  create_table "aven_workspace_roles", force: :cascade do |t|
    t.bigint "workspace_id"
    t.string "label", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id", "label"], name: "idx_aven_workspace_roles_on_ws_label", unique: true
    t.index ["workspace_id"], name: "index_aven_workspace_roles_on_workspace_id"
  end

  create_table "aven_workspace_user_roles", force: :cascade do |t|
    t.bigint "workspace_role_id"
    t.bigint "workspace_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_role_id", "workspace_user_id"], name: "idx_aven_ws_user_roles_on_role_user", unique: true
    t.index ["workspace_role_id"], name: "index_aven_workspace_user_roles_on_workspace_role_id"
    t.index ["workspace_user_id"], name: "index_aven_workspace_user_roles_on_workspace_user_id"
  end

  create_table "aven_workspace_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "workspace_id"], name: "idx_aven_workspace_users_on_user_workspace", unique: true
    t.index ["user_id"], name: "index_aven_workspace_users_on_user_id"
    t.index ["workspace_id"], name: "index_aven_workspace_users_on_workspace_id"
  end

  create_table "aven_workspaces", force: :cascade do |t|
    t.string "label"
    t.string "slug"
    t.text "description"
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_aven_workspaces_on_slug", unique: true
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.bigint "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
    t.index ["workspace_id"], name: "index_pg_search_documents_on_workspace_id"
  end

  create_table "test_projects", force: :cascade do |t|
    t.string "name"
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_test_projects_on_workspace_id"
  end

  create_table "test_resources", force: :cascade do |t|
    t.string "title"
    t.bigint "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_test_resources_on_workspace_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aven_agentic_agent_documents", "aven_agentic_agents", column: "agent_id"
  add_foreign_key "aven_agentic_agent_documents", "aven_agentic_documents", column: "document_id"
  add_foreign_key "aven_agentic_agent_tools", "aven_agentic_agents", column: "agent_id"
  add_foreign_key "aven_agentic_agent_tools", "aven_agentic_tools", column: "tool_id"
  add_foreign_key "aven_agentic_agents", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_agentic_document_embeddings", "aven_agentic_documents", column: "document_id"
  add_foreign_key "aven_agentic_documents", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_agentic_tool_parameters", "aven_agentic_tools", column: "tool_id"
  add_foreign_key "aven_agentic_tools", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_chat_messages", "aven_chat_messages", column: "parent_id"
  add_foreign_key "aven_chat_messages", "aven_chat_threads", column: "thread_id"
  add_foreign_key "aven_chat_threads", "aven_agentic_agents", column: "agent_id"
  add_foreign_key "aven_chat_threads", "aven_users", column: "user_id"
  add_foreign_key "aven_chat_threads", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_item_links", "aven_items", column: "source_id"
  add_foreign_key "aven_item_links", "aven_items", column: "target_id"
  add_foreign_key "aven_item_schemas", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_items", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_logs", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_workspace_roles", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_workspace_user_roles", "aven_workspace_roles", column: "workspace_role_id"
  add_foreign_key "aven_workspace_user_roles", "aven_workspace_users", column: "workspace_user_id"
  add_foreign_key "aven_workspace_users", "aven_users", column: "user_id"
  add_foreign_key "aven_workspace_users", "aven_workspaces", column: "workspace_id"
  add_foreign_key "pg_search_documents", "aven_workspaces", column: "workspace_id"
  add_foreign_key "test_projects", "aven_workspaces", column: "workspace_id"
  add_foreign_key "test_resources", "aven_workspaces", column: "workspace_id"
end
