# frozen_string_literal: true

module Xccdf
  # Methods related to saving profiles and finding which hosts they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def profiles
        @profiles ||= @op_profiles.map do |op_profile|
          ::Profile.from_openscap_parser(op_profile,
                                         benchmark_id: @benchmark&.id)
        end

        ::Profile.import!(@profiles.select(&:new_record?), ignore: true)
      end
      alias_method :save_profiles, :profiles
    end
  end
end
