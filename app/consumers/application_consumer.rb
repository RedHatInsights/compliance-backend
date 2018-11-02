# frozen_string_literal: true

# Parent class for all Racecar consumers, contains general logic
class ApplicationConsumer < Racecar::Consumer
  def current_user
    'testuser'
  end
end
