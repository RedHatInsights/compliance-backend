# frozen_string_literal: true

require 'test_helper'

# To test the RuleReference model
class RuleReferenceTest < ActiveSupport::TestCase
  should validate_presence_of(:label)
  should validate_length_of(:href).is_at_least(0)
  should_not allow_value(nil).for(:href)
  should validate_uniqueness_of(:label)
    .scoped_to(:href).with_message('and href combination already taken')
  should validate_uniqueness_of(:href)
    .scoped_to(:label).with_message('and label combination already taken')
  should have_many(:rule_references_rules).dependent(:delete_all)
  should have_many(:rules).through(:rule_references_rules)

  OP_RULE_REFERENCE = OpenStruct.new(href: '1', label: 'http://redhat.com')

  test 'builds a RuleReference from_openscap_parser' \
    'OpenscapParser::RuleReference' do
    rule_reference = RuleReference.from_openscap_parser(OP_RULE_REFERENCE)
    assert_equal OP_RULE_REFERENCE.href, rule_reference.href
    assert_equal OP_RULE_REFERENCE.label, rule_reference.label
    assert rule_reference.save
    assert_equal rule_reference.id,
                 RuleReference.from_openscap_parser(OP_RULE_REFERENCE).id
  end

  test 'finds an existing RuleReference from_oscap' do
    rule_reference = RuleReference.create!(OP_RULE_REFERENCE.to_h)
    assert_equal rule_reference.id,
                 RuleReference.find_unique([OP_RULE_REFERENCE]).first.id
  end
end
