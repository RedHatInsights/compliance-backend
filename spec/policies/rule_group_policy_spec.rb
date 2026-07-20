# frozen_string_literal: true

require 'rails_helper'

describe RuleGroupPolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:items) { FactoryBot.create_list(:rule_group, 20) }

  it_behaves_like 'globally available'
end
