# frozen_string_literal: true

module V2
  # Model for profile tailoring
  class Tailoring < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :tailorings

    belongs_to :policy, class_name: 'V2::Policy'
    belongs_to :profile, class_name: 'V2::Profile'
    has_one :security_guide, through: :profile, class_name: 'V2::SecurityGuide'
  end
end
