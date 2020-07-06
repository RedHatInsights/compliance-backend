# frozen_string_literal: true

# JSON API serialization for a BusinessObjective
class BusinessObjectiveSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title
  has_many :profiles do |business_objective|
    Pundit.policy_scope(User.current, Profile)
          .where(business_objective: business_objective)
  end
end
