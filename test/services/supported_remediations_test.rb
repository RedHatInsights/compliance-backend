# frozen_string_literal: true

require 'test_helper'

# A class to test the SupportedRemediations service
class SupportedRemediationsTest < ActiveSupport::TestCase
  test 'loads supported SSGs' do
    assert SupportedRemediations.revision
  end
end
