# frozen_string_literal: true

module V2
  # Model for user accounts
  class Account < ApplicationRecord
    has_many :policies, class_name: 'V2::Policy', dependent: :destroy
    has_many :systems, class_name: 'V2::System', dependent: nil
  end
end
