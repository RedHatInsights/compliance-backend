# frozen_string_literal: true

# A class to remove profiles on policies that do not have a matching ref_id
class IncorrectProfileRemover
  def self.run!
    counts = Policy.includes(:profiles).find_each.flat_map do |policy|
      next unless policy.profiles.length > 1

      find_incorrect_profiles(policy).destroy_all.count
    end.compact

    Logger.new(STDOUT).info "#{counts.sum} profiles removed from policies with "\
                            'mismatched ref_ids'
  end

  def self.find_incorrect_profiles(policy)
    Profile.where(policy: policy)
           .where.not(ref_id: policy.initial_profile.ref_id)
  end
end
