# frozen_string_literal: true

# JSON API serialization for Hosts
class HostSerializer
  include FastJsonapi::ObjectSerializer
  set_type :host
  attributes :name, :profiles, :compliant
end
