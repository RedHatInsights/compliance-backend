# frozen_string_literal: true

require 'rails_helper'

describe RulePolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:items) { FactoryBot.create_list(:rule, 20) }

  it_behaves_like 'globally available'
end
