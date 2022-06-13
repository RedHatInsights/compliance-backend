# frozen_string_literal: true

# Concern to provide a shortened ref_id
module ShortRefId
  SHORT_REF_ID_RE = /
    (?<=
      \Axccdf_org\.ssgproject\.content_profile_|
      \Axccdf_org\.ssgproject\.content_rule_
    ).*\z
  /x.freeze

  def short_ref_id
    ref_id.downcase[SHORT_REF_ID_RE] || ref_id
  end
end
