# frozen_string_literal: true

# Collection of profiles
class Policy < ApplicationRecord
  has_many :profiles, dependent: :nullify
end
