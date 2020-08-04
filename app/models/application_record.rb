# frozen_string_literal: true

# Abstract record class to be applied to all models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
