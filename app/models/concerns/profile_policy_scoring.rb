# frozen_string_literal: true

# Methods that are related to computing the score of a profile or a policy
module ProfilePolicyScoring
  def score(host: nil)
    results = test_results.latest
    results = results.where(host: host) if host
    return 0 if results.blank?

    ((scores = results.pluck(:score)).sum / scores.size).to_f
  end
end
