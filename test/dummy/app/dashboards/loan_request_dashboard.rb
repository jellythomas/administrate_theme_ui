require "administrate/base_dashboard"

class LoanRequestDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    amount: Field::Money,
    company: Field::BelongsTo,
    disbursed_on: Field::Date,
    notes: Field::Text,
    status: Field::StatusBadge.with_options(collection: LoanRequest::STATUSES, tones: { info: %w[admin_approval] }),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id company amount status disbursed_on].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id company amount status disbursed_on notes created_at].freeze
  FORM_ATTRIBUTES = %i[company amount status disbursed_on notes].freeze

  COLLECTION_FILTERS = {
    pending: ->(resources) { resources.where(status: "pending") },
    disbursed: ->(resources) { resources.where(status: "disbursed") },
    rejected: ->(resources) { resources.where(status: "rejected") }
  }.freeze

  def display_resource(loan) = "Loan ##{loan.id}"
end
