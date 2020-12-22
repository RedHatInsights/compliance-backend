# frozen_string_literal: true

# A service class to migrate profiles to be external before a certain date
class ExternalProfileUpdater
  class << self
    # rubocop:disable Rails/SkipsModelValidations
    def run!(date = DateTime.now)
      Profile.where('created_at < ?', date)
             .update_all(external: true)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
