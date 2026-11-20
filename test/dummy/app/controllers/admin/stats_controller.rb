module Admin
  class StatsController < Admin::ApplicationController
    def index
      loans = LoanRequest.all
      @stats = {
        limit: Company.sum(:credit_limit), companies: Company.count,
        disbursed: loans.where(status: "disbursed").sum(:amount), disbursed_count: loans.where(status: "disbursed").count,
        outstanding: loans.where(status: %w[approved sent_to_partner]).sum(:amount),
        pending: loans.where(status: %w[pending admin_approval]).count
      }
      months = (0..11).map { |i| i.months.ago.beginning_of_month.to_date }.reverse
      by_month = loans.group_by { |l| l.created_at.to_date.beginning_of_month }
      @trend = { labels: months.map { |m| m.strftime("%b") },
                 amount: months.map { |m| Array(by_month[m]).sum(&:amount).to_f },
                 count: months.map { |m| Array(by_month[m]).size } }
      @by_status = loans.group(:status).count
      @recent = loans.includes(:company).order(created_at: :desc).limit(6)
    end
  end
end
