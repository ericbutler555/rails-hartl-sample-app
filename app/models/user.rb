class User < ApplicationRecord

  # Track all the posts this user has:

  has_many :microposts, dependent: :destroy

  # Track how many users this user is following:

  # set a has_many relationship with the follower_id field in the Relationship model/db table:
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy

  # set a has_many relationship with the followed_id field in the Relationship model/db table (nicknamed "active_relationships" in the has_many block above):
  has_many :following, through: :active_relationships, source: :followed

  # Inverse: track how many followers a user has:

  # set a has_many relationship with the followed_id field in the Relationship model/db table:
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy

  # set a has_many relationship with the follower_id field in the Relationship model/db table (nicknamed "passive_relationships" in the has_many block above):
  has_many :followers, through: :passive_relationships, source: :follower

  # make an attribute available to the User model
  # to validate persistent user sessions
  attr_accessor :remember_token, :activation_token, :reset_token

  # force stored emails to all-lowercase
  before_save { email.downcase! }

  before_create :create_activation_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :name, presence: true,
                   length: { maximum: 50 }
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true,
                       length: { minimum: 6 },
                       allow_nil: true

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

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def activate
    update_columns(
      activated: true,
      activated_at: Time.zone.now
    )
# ^ refactored to only make 1 db query
#    update_attribute(:activated, true)
#    update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(
      reset_digest: User.digest(reset_token),
      reset_sent_at: Time.zone.now
    )
#    update_attribute(:reset_digest, User.digest(reset_token))
#    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # return a user's status feed:
  def feed
    following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
  end

  def follow(other_user)
    following << other_user
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  private

    def create_activation_token
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end

end
