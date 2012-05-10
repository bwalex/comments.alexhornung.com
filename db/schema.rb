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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120509182933) do

  create_table "articles", :force => true do |t|
    t.integer  "site_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "articles", ["name"], :name => "index_articles_on_name", :unique => true
  add_index "articles", ["site_id"], :name => "articles_site_id_fk"

  create_table "comments", :force => true do |t|
    t.integer  "article_id"
    t.boolean  "spam"
    t.string   "hashed_mail"
    t.string   "name"
    t.text     "comment"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "comments", ["article_id"], :name => "comments_article_id_fk"

  create_table "sessions", :force => true do |t|
    t.string "session_id"
    t.text   "data"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id", :unique => true

  create_table "site_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.integer  "access_level"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "site_users", ["site_id", "user_id"], :name => "index_site_users_on_site_id_and_user_id", :unique => true
  add_index "site_users", ["user_id"], :name => "site_users_user_id_fk"

  create_table "sites", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "key"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password"
    t.string   "salt"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_foreign_key "articles", "sites", :name => "articles_site_id_fk", :dependent => :delete

  add_foreign_key "comments", "articles", :name => "comments_article_id_fk", :dependent => :delete

  add_foreign_key "site_users", "sites", :name => "site_users_site_id_fk", :dependent => :delete
  add_foreign_key "site_users", "users", :name => "site_users_user_id_fk", :dependent => :delete

end
