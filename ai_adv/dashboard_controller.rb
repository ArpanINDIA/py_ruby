class DashboardController < ApplicationController
  before_action :authenticate_user! # If using Devise

  def index
    @transactions = current_user.transactions
    @time_period = params[:period] || "week"

    # Spending data for charts
    @spending_trend = spending_trend_data
    @spending_by_category = spending_by_category_data
    @spending_comparison = spending_comparison_data
    @largest_expenses = @transactions.order(amount: :desc).limit(5)
  end

  private

  def spending_trend_data
    current_user.transactions
               .group_by_period(@time_period, :date, range: 1.month.ago..Time.now)
               .sum(:amount)
  end

  def spending_by_category_data
    current_user.transactions
               .where(date: 1.month.ago..Time.now)
               .group(:category)
               .sum(:amount)
               .sort_by { |k, v| -v }
               .to_h
  end

  def spending_comparison_data
    current_month = current_user.transactions
                               .where(date: Time.now.beginning_of_month..Time.now.end_of_month)
                               .sum(:amount)

    last_month = current_user.transactions
                           .where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month)
                           .sum(:amount)

    { "Current Month" => current_month, "Last Month" => last_month }
  end
end