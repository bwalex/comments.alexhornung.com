require 'digest/md5'
require 'bcrypt'
require 'sanitize'
require './akismet.rb'

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end




class User < ActiveRecord::Base
  attr_accessor :new_password, :new_password_confirmation
  attr_accessor :remove_password


  has_many :site_users

  has_many :sites, :through => :site_users,
                   :uniq => true


  validates :name, :length => { :in => 2..40 }
  validates_confirmation_of :new_password, :if=>:password_changed?
  validates :email, :presence => true, :uniqueness => true, :email => true

  before_save :hash_new_password, :if => :password_changed?
  before_save :hash_mail

  def to_s
    self[:name]
  end

  def email=(mail)
    self[:email] = mail.strip.downcase
  end

  def password_changed?
    !@new_password.blank?
  end

  def as_json(options={})
    only = [
            :id,
            :email,
            :email_hashed,
            :name
           ]

    methods = []

    super(
      :only => only,
      :methods => methods
    )
  end


  def self.authenticate(email, password)
    # Because we use bcrypt we can't do this query in one part, first
    # we need to fetch the potential user
    if user = find_by_email(email)
      # Then compare the provided password against the hashed one in the db.
      if BCrypt::Password.new(user.password).is_password? password
        # If they match we return the user
        return user
      end
    end
    # If we get here it means either there's no user with that email, or the wrong
    # password was provided. But we don't want to let an attacker know which.
    return nil
  end


  private

  def hash_mail
    self[:email_hashed] = Digest::MD5.hexdigest(self[:email].strip.downcase)
  end

  def hash_new_password
    self[:password] = BCrypt::Password.create(@new_password)
  end
end


class SiteUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  validates_uniqueness_of :user_id, :scope => :site_id,
                                    :message => "already on that site"
  validates_presence_of :site
  validates_associated :site
  validates_presence_of :user
  validates_associated :user
end


class Site < ActiveRecord::Base
  has_many :site_users
  has_many :articles

  has_many :users, :through => :site_users,
                   :uniq => true
end


class Article < ActiveRecord::Base
  belongs_to :site
  has_many   :comments

  validates_presence_of :name
  validates :name, :length => { :in => 1..255 }
end


class Comment < ActiveRecord::Base
  attr_accessor :request
  attr_accessor :permalink

  belongs_to :article

  validates :email, :presence => true, :email => true
  validates :name, :length => { :in => 2..255 }
  validates :comment, :length => { :minimum => 2 }

  before_save :save_extra
  before_save :check_spam
  before_save :sanitize_comment

  def sanitize_comment
    self[:comment] = Sanitize.clean(self[:comment].gsub(/\n/, '<br>'), Sanitize::Config::BASIC)
    return true
  end

  def check_spam
    key = article.site.key
    url = article.site.url

    unless key.nil?
      Akismet.key = key
      Akismet.blog = url

      self[:spam] = Akismet.spam?({
        :comment_author => self[:name],
        :comment_author_email => self[:email],
        :comment_content => self[:comment],
        :permalink => @permalink
      }, @request)
    end

    return true
  end

  def email= mail
    self[:email] = mail.strip.downcase
  end

  def save_extra
    self[:hashed_mail] = Digest::MD5.hexdigest(self[:email].strip.downcase)
    self[:ip] = @request.ip
    return true
  end

  def created_at
    return (self[:created_at] != nil) ? self[:created_at].strftime("%d/%m/%Y - %H:%M") : nil
  end

  def updated_at
    return (self[:updated_at] != nil) ? self[:updated_at].strftime("%d/%m/%Y - %H:%M") : nil
  end
end




class ActiveRecord::RecordInvalid
  def errors_to_a
    a = []

    record.errors.each do |k, v|
      a.push(k.to_s.split("_").each{|w| w.capitalize!}.join(" ") + " " + v);
    end

    return a
  end

  def errors_to_json
    { "errors" => errors_to_a }.to_json
  end
end
