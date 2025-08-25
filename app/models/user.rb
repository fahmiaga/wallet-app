require "securerandom"
require "openssl"

class User < ApplicationRecord
  has_one :wallet, as: :owner, dependent: :destroy
  after_create -> { create_wallet!(currency: "IDR", name: "main") }

  validates :email, presence: true, uniqueness: true

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
end
