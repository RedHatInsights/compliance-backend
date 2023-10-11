# frozen_string_literal: true

module V2
  class Account < ApplicationRecord
    has_many :users, dependent: :nullify

    has_many :policies, dependent: :destroy
  end
end
