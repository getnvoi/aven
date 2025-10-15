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

ActiveRecord::Schema[8.0].define(version: 2025_01_14_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "aven_app_record_schemas", force: :cascade do |t|
    t.jsonb "schema", null: false
    t.bigint "workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["schema"], name: "index_aven_app_record_schemas_on_schema", using: :gin
    t.index ["workspace_id"], name: "index_aven_app_record_schemas_on_workspace_id"
  end

  create_table "aven_app_records", force: :cascade do |t|
    t.jsonb "data", null: false
    t.bigint "app_record_schema_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_record_schema_id"], name: "index_aven_app_records_on_app_record_schema_id"
    t.index ["data"], name: "index_aven_app_records_on_data", using: :gin
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

  add_foreign_key "aven_app_record_schemas", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_app_records", "aven_app_record_schemas", column: "app_record_schema_id"
  add_foreign_key "aven_logs", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_workspace_roles", "aven_workspaces", column: "workspace_id"
  add_foreign_key "aven_workspace_user_roles", "aven_workspace_roles", column: "workspace_role_id"
  add_foreign_key "aven_workspace_user_roles", "aven_workspace_users", column: "workspace_user_id"
  add_foreign_key "aven_workspace_users", "aven_users", column: "user_id"
  add_foreign_key "aven_workspace_users", "aven_workspaces", column: "workspace_id"
  add_foreign_key "test_projects", "aven_workspaces", column: "workspace_id"
  add_foreign_key "test_resources", "aven_workspaces", column: "workspace_id"
end
