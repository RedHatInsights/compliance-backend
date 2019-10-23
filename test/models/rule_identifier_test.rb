# frozen_string_literal: true

require 'test_helper'

# To test the RuleIdentifier model
class RuleIdentifierTest < ActiveSupport::TestCase
  should validate_presence_of(:label)
  should validate_presence_of(:system)
  should belong_to(:rule)

  OP_RULE_IDENTIFIER = OpenStruct.new(system: 'http://redhat.com',
                                      label: '01-4H')

  test 'builds a RuleIdentifier from_openscap_parser' \
    'OpenscapParser::RuleIdentifier' do
    rule_identifier = RuleIdentifier.from_openscap_parser(OP_RULE_IDENTIFIER)
    assert_equal OP_RULE_IDENTIFIER.system, rule_identifier.system
    assert_equal OP_RULE_IDENTIFIER.label, rule_identifier.label
    rule_identifier.rule = rules(:one)
    assert rule_identifier.save
    assert_nil RuleIdentifier.from_openscap_parser(OP_RULE_IDENTIFIER).id
  end
end
