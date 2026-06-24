class SortedFxAdapter < Fx::Adapters::Postgres
  def functions
    super.sort_by { |fn| [fn.name, fn.definition] }
  end

  def triggers
    super.sort_by { |tr| [tr.name, tr.definition] }
  end
end

Fx.configure do |config|
  config.database = SortedFxAdapter.new
end
