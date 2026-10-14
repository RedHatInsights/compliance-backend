# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob do
  it 'registers retries for selected transient Active Record failures' do
    handled_exceptions = described_class.rescue_handlers.map(&:first)

    expect(handled_exceptions).to include(
      'ActiveRecord::Deadlocked',
      'ActiveRecord::ConnectionFailed',
      'ActiveRecord::ConnectionNotEstablished',
      'ActiveRecord::SerializationFailure'
    )
  end

  it 'does not install a catch-all StandardError retry handler' do
    handled_exceptions = described_class.rescue_handlers.map(&:first)

    expect(handled_exceptions).not_to include('StandardError')
  end
end
