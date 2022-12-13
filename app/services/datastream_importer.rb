# frozen_string_literal: true

# This class imports pre-parsed datastream info into the compliance DB
class DatastreamImporter
  include ::Xccdf::Util
  include ::Xccdf::Datastreams

  def initialize(datastream_filename)
    @op_benchmark = op_datastream_file(datastream_filename).benchmark
    @op_profiles = @op_benchmark.profiles
    @op_rule_groups = @op_benchmark.groups
    @op_rules = @op_benchmark.rules
    @op_value_definitions = @op_benchmark.values
    @op_rule_references =
      @op_benchmark.rule_references.reject { |rr| rr.label.empty? }
  end

  def import!
    Xccdf::Benchmark.transaction do
      save_all_benchmark_info
    end
  end
end
