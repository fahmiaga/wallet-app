class Team < ApplicationRecord
  has_one :wallet, as: :owner, dependent: :destroy
  after_create -> { create_wallet!(currency: "IDR", name: "main") }
end
