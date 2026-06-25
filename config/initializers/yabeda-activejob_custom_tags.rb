# frozen_string_literal: true

# Patch for https://github.com/Fullscript/yabeda-activejob/pull/26
#
# We need custom tags on ActiveJob metrics (see ParseReportJob#yabeda_tags), but the
# feature only exists on an unreleased fork (RoamingNoMaD/yabeda-activejob). Konflux
# hermetic builds block network access and cannot install git-sourced gems, so using
# that fork directly is not viable. This patch backports the two relevant changes from
# the upstream PR into the released 0.6.0 gem until the PR is merged and released.
#
# NOTE: Released 0.6.0 does not have an EventHandler class (unlike the fork). The
# perform.active_job subscription is an inline block inside install!. We patch install!
# via prepend to replace that subscription with one that merges custom tags.
#
# This file is named yabeda-activejob_custom_tags.rb (with a hyphen) so that it sorts
# before yabeda.rb alphabetically and loads before install! is called.
#
# Once that PR is merged and a new gem version is released:
#   1. Delete this file.
#   2. In Gemfile, bump yabeda-activejob to the version that includes the PR.
#   3. Run `bundle install` to update Gemfile.lock.

require 'yabeda/activejob'

module Yabeda
  module ActiveJob
    def self.custom_tags(job)
      return {} unless job.respond_to?(:yabeda_tags)

      if job.method(:yabeda_tags).arity.zero?
        job.yabeda_tags
      else
        job.yabeda_tags(*job.arguments)
      end
    end
  end
end

Yabeda::ActiveJob.singleton_class.prepend(Module.new do
  def install!
    super
    ActiveSupport::Notifications.notifier.listeners_for('perform.active_job').each do |listener|
      ActiveSupport::Notifications.unsubscribe(listener)
    end
    ActiveSupport::Notifications.subscribe('perform.active_job') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      job = event.payload[:job]
      labels = {
        activejob: job.class.to_s,
        queue: job.queue_name.to_s,
        executions: job.executions.to_s,
      }.merge(Yabeda::ActiveJob.custom_tags(job))
      if event.payload[:exception].present?
        Yabeda.activejob_failed_total.increment(labels.merge(failure_reason: event.payload[:exception].first.to_s))
      else
        Yabeda.activejob_success_total.increment(labels)
      end
      Yabeda.activejob_executed_total.increment(labels)
      Yabeda.activejob_runtime.measure(labels, Yabeda::ActiveJob.ms2s(event.duration))
      Yabeda::ActiveJob.after_event_block.call(event) if Yabeda::ActiveJob.after_event_block.respond_to?(:call)
    end
  end
end)
