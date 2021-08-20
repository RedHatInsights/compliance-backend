# frozen_string_literal: true

# Class that deduplicates canonical profiles with identical benchmark/ref IDs
class DuplicateCanonicalProfileResolver
  class << self
    def run!
      duplicates.each do |duplicate|
        profiles = Profile.canonical.includes(:child_profiles).where(
          duplicate.slice(:ref_id, :benchmark_id)
        ).order(created_at: :asc).offset(1)

        return duplicate_error_msg(duplicate) unless no_child_profiles? profiles

        profiles.destroy_all
        duplicate_success_msg(duplicate)
      end
    end

    private

    def duplicates
      Profile.canonical.select(
        :ref_id,
        :benchmark_id,
        :policy_id,
        'COUNT(profiles.id)'
      ).group(
        :ref_id,
        :benchmark_id,
        :policy_id
      ).having('count(profiles.id) > 1')
    end

    def no_child_profiles?(profiles)
      profiles.all? { |p| p.child_profiles.count.zero? }
    end

    def duplicate_success_msg(duplicate)
      STDOUT.puts(%(
        Deleted #{duplicate.count - 1} duplicates of policy with
        ref_id=#{duplicate.ref_id} and benchmark_id=#{duplicate.benchmark_id}.
      ))
    end

    def duplicate_error_msg(duplicate)
      warn(
        %(Duplicate policy with child profiles detected with
        ref_id=#{duplicate.ref_id} benchmark_id=#{duplicate.benchmark_id},
        skipping its cleanup."
        ).gsub(/\s+/, ' ').strip
      )
    end
  end
end
