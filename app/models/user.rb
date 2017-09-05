class User < ApplicationRecord

  # make an attribute available to the User model
  # to validate persistent user sessions
  attr_accessor :remember_token

  # force stored emails to all-lowercase
  before_save { email.downcase! }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :name, presence: true,
                   length: { maximum: 50 }
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true,
                       length: { minimum: 6 }

  # manually create bcrypted string hashes,
  # for testing passwords (see /test/fixtures/users.yml)
  # and generating hashed session tokens
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # create a random "token" for storing user sessions
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # save a hashed token to the db users table,
  # for validating persistent user sessions
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # remove the saved token hash from the db users table
  def forget
    update_attribute(:remember_digest, nil)
  end

  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

end
