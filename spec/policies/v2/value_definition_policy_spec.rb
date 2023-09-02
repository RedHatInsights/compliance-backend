# frozen_string_literal: true

require 'rails_helper'

describe V2::RulePolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:items) { FactoryBot.create_list(:v2_value_definition, 20) }

  it_behaves_like 'globally available'
end
