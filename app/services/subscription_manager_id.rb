# frozen_string_literal: true

# Host-level subscription_manager_id values from inventory events and Satellite headers.
module SubscriptionManagerId
  class Malformed < StandardError; end

  module_function

  def absent?(value)
    value.nil? || (value.is_a?(String) && value.strip.empty?)
  end

  def for_import(value)
    return nil if absent?(value)

    canonical(value) || raise(Malformed)
  end

  def canonical(value)
    return nil if absent?(value)
    return nil unless value.is_a?(String)

    candidate = value.strip
    return nil unless persistence_compatible?(candidate)

    candidate
  end

  def persistence_compatible?(candidate)
    return false unless UUID.validate(candidate)

    type = System.type_for_attribute(:subscription_manager_id)
    serialized = type.serialize(candidate)
    !serialized.nil? && !type.cast(serialized).nil?
  end
end
