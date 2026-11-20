class Company < ApplicationRecord
  has_many :loan_requests, dependent: :destroy
  validates :name, presence: true, length: { minimum: 3 }
  validates :credit_limit, numericality: { greater_than: 0 }
end
