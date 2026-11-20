module <%= ns_class %>
  class <%= class_name %>Controller < <%= ns_class %>::ApplicationController
    def index
      # Replace with real queries. Keep heavy aggregates in a query object and cache them.
      @stats = {
        total: 0,
        this_month: 0
      }
      @trend = { labels: (1..6).map { |i| i.months.ago.strftime("%b") }.reverse, values: Array.new(6, 0) }
    end
  end
end
