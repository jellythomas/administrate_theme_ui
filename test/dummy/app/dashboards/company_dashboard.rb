require "administrate/base_dashboard"

class CompanyDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    status: Field::StatusBadge.with_options(collection: %w[active pending inactive blocked]),
    credit_limit: Field::Money,
    active: Field::Boolean,
    loan_requests: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id name status credit_limit active].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id name status credit_limit active created_at loan_requests].freeze
  FORM_ATTRIBUTES = %i[name status credit_limit active].freeze

  COLLECTION_FILTERS = {
    active: ->(resources) { resources.where(active: true) },
    blocked: ->(resources) { resources.where(status: "blocked") }
  }.freeze

  def display_resource(company) = company.name
end
