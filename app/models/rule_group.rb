# frozen_string_literal: true

# OpenSCAP RuleGroup
class RuleGroup < ApplicationRecord
  # Need to set primary key format to work with uuid primary key column
  has_ancestry(primary_key_format: %r{\A[\w\-]+(\/[\w\-]+)*\z})

  has_many :profile_rule_groups, dependent: :delete_all
  has_many :profiles, through: :profile_rule_groups, source: :profile
  has_many :left_rule_group_relationships, dependent: :delete_all, foreign_key: :left_id,
                                           inverse_of: :left, class_name: 'RuleGroupRelationship'
  has_many :right_rule_group_relationships, dependent: :delete_all, foreign_key: :right_id,
                                            inverse_of: :right, class_name: 'RuleGroupRelationship'

  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'

  validates :title, presence: true
  validates :ref_id, uniqueness: { scope: %i[benchmark_id] }, presence: true
  validates :description, presence: true
  validates :benchmark_id, presence: true

  def self.from_openscap_parser(op_rule_group, benchmark_id: nil, parent_id: nil)
    rule_group = find_or_initialize_by(ref_id: op_rule_group.id,
                                       benchmark_id: benchmark_id)

    rule_group.assign_attributes(title: op_rule_group.title,
                                 description: op_rule_group.description,
                                 rationale: op_rule_group.rationale,
                                 parent_id: parent_id)

    rule_group
  end
end
