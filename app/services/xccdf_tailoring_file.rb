# frozen_string_literal: true

# A class representing an XCCDF Tailoring File
class XccdfTailoringFile
  extend Forwardable

  XCCDF = 'xccdf'

  def initialize(profile:, rule_ref_ids: [], set_values: {})
    @profile = profile
    @rule_ref_ids = rule_ref_ids
    @set_values = set_values
  end

  def_delegator :builder, :to_xml

  private

  def builder
    @builder ||= create_builder do |xml|
      xml[XCCDF].benchmark(id: @profile.benchmark.ref_id)
      xml[XCCDF].version(1, time: DateTime.now.iso8601)
      xml[XCCDF].Profile(id: @profile.ref_id,
                         extends: @profile.parent_profile.ref_id)
    end
  end

  def create_builder
    handle_missing_parent_profile
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml[XCCDF].Tailoring('xmlns:xccdf' =>
                           'http://checklists.nist.gov/xccdf/1.2',
                           id: 'xccdf_csfr-compliance_tailoring_default') do
        yield xml
      end
    end
  end

  def handle_missing_parent_profile
    e = ArgumentError.new("Profile(id=#{@profile.id}) has no parent profile.")
    raise e if @profile.parent_profile.nil?
  end
end
