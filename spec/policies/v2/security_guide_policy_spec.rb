# frozen_string_literal: true

require 'rails_helper'

describe V2::SecurityGuidePolicy do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:items) { FactoryBot.create_list(:v2_security_guide, 20) }

  it_behaves_like 'globally available'
end
