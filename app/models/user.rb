require "securerandom"
require "openssl"

class User < ApplicationRecord
  has_one :wallet, as: :owner, dependent: :destroy
  after_create -> { create_wallet!(currency: "IDR", name: "main") }

  validates :email, presence: true, uniqueness: true

  validate :password_required

  def password=(raw)
    self.password_salt = SecureRandom.hex(16)
    self.password_hash = self.class.hash_password(raw, password_salt)
  end

  def authenticate(raw)
    self.password_hash == self.class.hash_password(raw, password_salt)
  end

  def self.hash_password(raw, salt)
    OpenSSL::Digest::SHA256.hexdigest("#{salt}--#{raw}")
  end

  def switch_wallet(wallet_id)
    wallets.find_by(id: wallet_id)
  end

  private

  def password_required
    errors.add(:password, "can't be blank") if password_hash.nil? || password_hash.empty?
  end
end
