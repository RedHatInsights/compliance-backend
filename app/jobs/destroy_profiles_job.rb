# frozen_string_literal: true

# Job meant to destroy profiles and associated objects asynchronously
class DestroyProfilesJob
  include Sidekiq::Worker

  def perform(ids)
    Profile.where(id: ids).destroy_all
  end
end
