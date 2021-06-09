# frozen_string_literal: true

# Methods that are related to computing the score of a profile or a policy
module ProfilePolicyScoring
  def score(host: nil)
    return super().to_f unless host

    test_results.latest.where(host: host).average(:score).to_f
  end

  def calculate_score!(*_args)
    update!(score: test_results.latest.average(:score).to_f)
  end
end
