# frozen_string_literal: true

module Xccdf
  # Methods related to saving xccdf security guides
  module SecurityGuides
    extend ActiveSupport::Concern

    included do
      def save_security_guide
        security_guide.package_name = package_name

        return unless security_guide.new_record? || security_guide.package_name_changed?

        security_guide.save!
      end

      def security_guide_saved?
        security_guide.package_name == package_name && security_guide.persisted?
      end

      def security_guide_profiles_saved?
        security_guide.profiles.count == @op_security_guide.profiles.count
      end

      def security_guide_rules_saved?
        security_guide.rules.count == @op_security_guide.rules.count
      end

      def security_guide_contents_equal_to_op?
        return false if Settings.force_import_ssgs

        security_guide_saved? && security_guide_rules_saved? && security_guide_profiles_saved?
      end

      def security_guide
        @security_guide ||= ::V2::SecurityGuide.from_parser(@op_security_guide)
      end

      def package_name
        @package_name ||= begin
          SupportedSsg.by_os_major[security_guide.ref_id[/(?<=RHEL-)\d+/]].find do |item|
            item.version == security_guide.version
          end&.package
        end
      end
    end
  end
end
