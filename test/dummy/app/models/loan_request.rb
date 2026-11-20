class LoanRequest < ApplicationRecord
  STATUSES = %w[pending admin_approval sent_to_partner approved disbursed rejected closed].freeze
  belongs_to :company
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
end
