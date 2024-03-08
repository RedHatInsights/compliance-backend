# frozen_string_literal: true

module V2
  # A class representing an XCCDF Tailoring File
  class XccdfTailoringFile
    extend Forwardable

    XCCDF = 'xccdf'

    def initialize(profile:, rules: {}, set_values: {}, rule_group_ref_ids: [])
      @tailoring = profile
      @rules = rules
      @rule_group_ref_ids = rule_group_ref_ids
      @set_values = set_values
    end

    def output
      builder.to_xml
    end

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
        id: @tailoring.security_guide.ref_id,
        version: @tailoring.security_guide.version,
        href: "ssg-rhel#{@tailoring.security_guide.os_major_version}-ds.xml"
      )
    end

    def profile_builder(xml)
      xml[XCCDF].Profile(id: @tailoring.policy.ref_id, extends: @tailoring.profile.ref_id) do
        xml[XCCDF].title(@tailoring.profile.title,
                         'xmlns:xhtml' => 'http://www.w3.org/1999/xhtml',
                         'xml:lang' => 'en-US', override: true)
        xml[XCCDF].description(@tailoring.profile.description,
                               'xmlns:xhtml' => 'http://www.w3.org/1999/xhtml',
                               'xml:lang' => 'en-US', override: true)
        tailoring_builder(xml)
      end
    end

    def rule_selections_builder(xml)
      @rules.each { |rule| xml[XCCDF].select(idref: rule.ref_id, selected: rule.selected) }
    end

    def rule_group_selections_builder(xml)
      @rule_group_ref_ids.each { |ref_id| xml[XCCDF].select(idref: ref_id, selected: true) }
    end

    def value_builder(xml)
      @set_values.each do |value_ref_id, value|
        # nokogiri maintainers recommend using send for tags with hyphens
        xml[XCCDF].send('set-value', value, idref: value_ref_id)
      end
    end

    def tailoring_builder(xml)
      rule_selections_builder(xml)
      rule_group_selections_builder(xml)
      value_builder(xml)
    end

    def create_builder
      validate_input
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml[XCCDF].Tailoring(
          'xmlns:xccdf' => 'http://checklists.nist.gov/xccdf/1.2',
          id: 'xccdf_csfr-compliance_tailoring_default'
        ) do
          yield xml
        end
      end
    end

    def validate_input
      handle_missing_profile
      handle_missing_rules
    end

    def handle_missing_rules
      missing_rules = @rules.select(&:selected).map(&:ref_id) -
                      @tailoring.profile.rules.map(&:ref_id) -
                      @tailoring.security_guide.rules.map(&:ref_id)
      e = ArgumentError.new("SecurityGuide(id=#{@tailoring.security_guide.id}) does not " \
                            "contain selected rules: #{missing_rules.join(', ')}")
      raise e if missing_rules.any?
    end

    def handle_missing_profile
      e = ArgumentError.new("Tailoring(id=#{@tailoring.id}) has no original profile.")
      raise e if @tailoring.profile.nil?
    end
  end
end
