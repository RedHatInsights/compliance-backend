# frozen_string_literal: true

# Config file revisions (i.e. from compliance-ssg)
class Revision < ApplicationRecord
  validates :name, uniqueness: true, presence: true
  validates :revision, presence: true

  class << self
    def datastreams
      find_by(name: 'datastreams')&.revision
    end

    def datastreams=(revision)
      find_or_create_by(name: 'datastreams').update!(revision: revision)
    end

    def remediations
      find_by(name: 'remediations')&.revision
    end

    def remediations=(revision)
      find_or_create_by(name: 'remediations').update!(revision: revision)
    end
  end
end
