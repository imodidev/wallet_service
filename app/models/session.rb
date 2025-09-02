class Session < ApplicationRecord
  belongs_to :user
  
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create
  
  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  
  def self.create_for_user(user)
    create!(user: user)
  end
  
  def active?
    expires_at > Time.current
  end
  
  def expired?
    !active?
  end
  
  def self.cleanup_expired
    expired.delete_all
  end
  
  private
  
  def generate_token
    self.token = SecureRandom.hex(32)
  end
  
  def set_expiration
    self.expires_at = 24.hours.from_now
  end
end
