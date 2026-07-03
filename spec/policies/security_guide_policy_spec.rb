# frozen_string_literal: true

require 'rails_helper'

describe SecurityGuidePolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:items) { FactoryBot.create_list(:security_guide, 20) }

  it_behaves_like 'globally available'
end
