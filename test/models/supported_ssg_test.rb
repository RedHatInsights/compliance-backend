# frozen_string_literal: true

require 'test_helper'

class SupportedSsgTest < ActiveSupport::TestCase
  test 'loads supported SSGs' do
    assert SupportedSsg.all
  end

  test 'provides revision' do
    assert SupportedSsg.revision
  end
end
