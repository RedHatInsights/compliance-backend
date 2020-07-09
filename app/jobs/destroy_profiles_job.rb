# frozen_string_literal: true

# Job meant to destroy profiles and associated objects asynchronously
class DestroyProfilesJob
  include Sidekiq::Worker

  def perform(ids)
    Sidekiq.logger.info("Destroying profiles with IDs: #{ids}...")
    Profile.where(id: ids).destroy_all
    Sidekiq.logger.info('Finished')
  end
end
