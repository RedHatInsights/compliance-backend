class SortedFxAdapter < Fx::Adapters::Postgres
  def functions
    super.sort_by(&:name)
  end

  def triggers
    super.sort_by(&:name)
  end
end

Fx.configure do |config|
  config.database = SortedFxAdapter.new
end
