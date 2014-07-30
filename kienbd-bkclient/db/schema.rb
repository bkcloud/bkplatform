# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130828021909) do

  create_table "admins", force: true do |t|
    t.string   "username",               default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree
  add_index "admins", ["username"], name: "index_admins_on_username", unique: true, using: :btree

  create_table "disk_offerings", force: true do |t|
    t.string   "disk_offering_id"
    t.string   "disksize"
    t.string   "storagetype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instances", force: true do |t|
    t.integer  "user_id"
    t.string   "instance_id"
    t.string   "job_created_id"
    t.string   "job_id"
    t.integer  "service_offering_id"
    t.integer  "disk_offering_id"
    t.integer  "template_id"
    t.string   "name",                default: "",        null: false
    t.string   "displayname",         default: "",        null: false
    t.string   "hostname",            default: "",        null: false
    t.string   "port",                default: "",        null: false
    t.string   "state",               default: "pending", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_offerings", force: true do |t|
    t.string   "service_offering_id"
    t.integer  "cpunumber"
    t.integer  "cpuspeed"
    t.integer  "memory"
    t.boolean  "offerha"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "templates", force: true do |t|
    t.string   "template_id"
    t.string   "name"
    t.string   "ostypename"
    t.string   "details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "phone"
    t.string   "username"
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
