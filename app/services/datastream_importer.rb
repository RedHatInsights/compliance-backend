# frozen_string_literal: true

# This class imports pre-parsed datastream info into the compliance DB
class DatastreamImporter
  include ::Xccdf::Util
  include ::Xccdf::Datastreams

  def initialize(datastream_filename)
    @op_security_guide = op_datastream_file(datastream_filename).benchmark
    @op_profiles = @op_security_guide.profiles
    @op_rule_groups = @op_security_guide.groups
    @op_rules = @op_security_guide.rules
    @op_value_definitions = @op_security_guide.values
    @op_rule_references = @op_security_guide.rule_references.reject { |rr| rr.label.empty? }
  end

  def import!
    ::V2::SecurityGuide.transaction do
      save_all_security_guide_info
    end
  end
end
