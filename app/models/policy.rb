# frozen_string_literal: true

# Collection of profiles
class Policy < ApplicationRecord
  scoped_search on: %i[id name]
  has_many :profiles, dependent: :nullify
end
