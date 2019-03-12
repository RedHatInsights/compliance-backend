# frozen_string_literal: true

# Methods that are shared between system-like models, like
# Hosts and Imagestreams.
module SystemLike
  extend ActiveSupport::Concern

  included do
    scoped_search on: %i[id name]
    has_many :rule_results, dependent: :destroy
    has_many :rules, through: :rule_results, source: :rule
    belongs_to :account, optional: true
  end

  def compliant
    result = {}
    profiles.map do |profile|
      result[profile.ref_id] = profile.compliant?(self)
    end
    result
  end
end
