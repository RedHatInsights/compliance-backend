# frozen_string_literal: true

# Pseudo-class for retrieving supported OS major versions
class OsMajorVersion < ApplicationRecord
  OS_MAJOR_VERSION = Arel.sql(
    <<-SQL.gsub("\n", ' ').squeeze(' ')
      REPLACE(ref_id, '#{Xccdf::Benchmark::REF_PREFIX}-', '')::int
      AS os_major_version
    SQL
  )

  self.table_name = 'benchmarks'

  default_scope do
    select(OS_MAJOR_VERSION, :ref_id).distinct.order(:os_major_version)
  end

  has_many :benchmarks, class_name: 'Xccdf::Benchmark',
                        foreign_key: 'ref_id', primary_key: 'ref_id',
                        inverse_of: false, dependent: :restrict_with_exception

  def readonly?
    true
  end

  def os_major_version
    attributes['os_major_version']
  end

  def supported_profiles
    versions = SupportedSsg.by_os_major[os_major_version.to_s].map(&:version)

    Profile.canonical.joins(:benchmark)
           .where(benchmarks: { ref_id: ref_id, version: versions })
           .order(:ref_id, Arel.sql('
             string_to_array("benchmarks"."version", \'.\')::int[] DESC
           '))
           .select('DISTINCT ON ("profiles"."ref_id") "profiles".*')
  end
end
