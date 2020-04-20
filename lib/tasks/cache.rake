# frozen_string_literal: true

desc <<-END_DESC
  Warms all possible objects in the cache.
END_DESC

task warm_cache: :environment do
  begin
    CacheHelper.warm
  rescue StandardError => e
    ExceptionNotifier.notify_exception(
      e,
      data: OpenshiftEnvironment.summary
    )
  end
end
