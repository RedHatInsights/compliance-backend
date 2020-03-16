# frozen_string_literal: true

# A class representing an XCCDF Tailoring File
class XccdfTailoringFile
  extend Forwardable

  XCCDF = 'xccdf'

  def initialize(profile:, rule_ref_ids: {}, set_values: {})
    @profile = profile
    @rule_ref_ids = rule_ref_ids
    @set_values = set_values
  end

  def_delegator :builder, :to_xml

  private

  def builder
    @builder ||= create_builder do |xml|
      benchmark_builder(xml)
      xml[XCCDF].version(1, time: DateTime.now.iso8601)
      profile_builder(xml)
    end
  end

  def benchmark_builder(xml)
    xml[XCCDF].benchmark(
      id: @profile.benchmark.ref_id,
      version: @profile.benchmark.version,
      href: "ssg-rhel#{@profile.benchmark.inferred_os_major_version}-ds.xml"
    )
  end

  def profile_builder(xml)
    xml[XCCDF].Profile(id: @profile.ref_id,
                       extends: @profile.parent_profile.ref_id) do
      xml[XCCDF].title(@profile.name,
                       'xmlns:xhtml' => 'http://www.w3.org/1999/xhtml',
                       'xml:lang' => 'en-US', override: true)
      xml[XCCDF].description(@profile.description,
                             'xmlns:xhtml' => 'http://www.w3.org/1999/xhtml',
                             'xml:lang' => 'en-US', override: true)
      rule_selections_builder(xml)
    end
  end

  def rule_selections_builder(xml)
    @rule_ref_ids.each do |rule_ref_id, selected|
      xml[XCCDF].select(idref: rule_ref_id, selected: selected)
    end
  end

  def create_builder
    validate_input
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml[XCCDF].Tailoring('xmlns:xccdf' =>
                           'http://checklists.nist.gov/xccdf/1.2',
                           id: 'xccdf_csfr-compliance_tailoring_default') do
        yield xml
      end
    end
  end

  def validate_input
    handle_missing_parent_profile
    handle_missing_rules
  end

  def handle_missing_rules
    missing_rules = @rule_ref_ids.keys -
                    @profile.benchmark.rules
                            .where(ref_id: @rule_ref_ids.keys).pluck(:ref_id)

    e = ArgumentError.new("Benchmark(id=#{@profile.benchmark.id}) does not "\
                          "contain selected rules: #{missing_rules.join(', ')}")
    raise e if missing_rules.any?
  end

  def handle_missing_parent_profile
    e = ArgumentError.new("Profile(id=#{@profile.id}) has no parent profile.")
    raise e if @profile.parent_profile.nil?
  end
end
