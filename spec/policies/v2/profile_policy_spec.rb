# frozen_string_literal: true

require 'rails_helper'

describe V2::ProfilePolicy do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:items) { FactoryBot.create_list(:v2_profile, 20) }

  it_behaves_like 'globally available'
end
