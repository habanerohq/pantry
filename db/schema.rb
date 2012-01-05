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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111229222942) do

  create_table "composites", :force => true do |t|
    t.string   "some_identifying_value"
    t.integer  "whole_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "describeds", :force => true do |t|
    t.string   "descriptor"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "labelleds", :force => true do |t|
    t.string   "label"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nameds", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "valueds", :force => true do |t|
    t.string   "discriminator"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
