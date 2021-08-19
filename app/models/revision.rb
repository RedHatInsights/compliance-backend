# frozen_string_literal: true

# Config file revisions (i.e. from compliance-ssg)
class Revision < ApplicationRecord
  validates :name, uniqueness: true, presence: true
  validates :revision, presence: true
end
