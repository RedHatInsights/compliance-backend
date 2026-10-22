# frozen_string_literal: true

# Parent class for all background jobs
class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked,
           ActiveRecord::ConnectionFailed,
           ActiveRecord::ConnectionNotEstablished,
           ActiveRecord::SerializationFailure,
           wait: :polynomially_longer,
           attempts: 3
end
