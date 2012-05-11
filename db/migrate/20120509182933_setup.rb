class Setup < ActiveRecord::Migration
  def self.up
    create_table :sites, :force => true do |t|
      t.string :name
      t.string :url
      t.string :key
      t.timestamps
    end

    create_table :articles do |t|
      t.references :site
      t.string     :name
      t.timestamps
    end

    add_foreign_key(:articles, :sites, :dependent => :delete)
    add_index :articles, :name, :unique => true


    create_table :comments do |t|
      t.references :article
      t.boolean    :spam
      t.string     :email
      t.string     :hashed_mail
      t.string     :name
      t.string     :ip
      t.text       :comment
      t.timestamps
    end

    add_foreign_key(:comments, :articles, :dependent => :delete)


    create_table :sessions do |t|
      t.string :session_id
      t.text :data
    end

    add_index :sessions, :session_id, :unique => true


    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :openid
      t.string :password
      t.string :salt
      t.timestamps
    end

    add_index :users, :openid, :unique => false #otherwise we can't have NULLs


    create_table :site_users do |t|
      t.references :user
      t.references :site
      t.integer :access_level

      t.timestamps
    end

    add_foreign_key(:site_users, :users, :dependent => :delete)
    add_foreign_key(:site_users, :sites, :dependent => :delete)
    add_index :site_users, [:site_id, :user_id], :unique => true
  end


  def self.down
    drop_table :comments
    drop_table :articles
    drop_table :sites
  end
end
