# frozen_string_literal: true

# Class to batch collection loading
class CollectionLoader < GraphQL::Batch::Loader
  def initialize(model, association_name, where: nil)
    @model = model
    @association_name = association_name
    @where = where
    validate
  end

  def load(record)
    unless record.is_a?(@model)
      raise TypeError,
            "#{@model} loader can't load association for #{record.class}"
    end

    if association_loaded?(record)
      return Promise.resolve(read_association(record))
    end

    super
  end

  def perform(records)
    preload_association(records)
    records = records.where(@where) if @where.present?
    records.each { |record| fulfill(record, read_association(record)) }
  end

  private

  def validate
    return if @model.reflect_on_association(@association_name)

    raise ArgumentError, "No association #{@association_name} on #{@model}"
  end

  def preload_association(records)
    ::ActiveRecord::Associations::Preloader.new(records: records, associations: @association_name).call
  end

  def read_association(record)
    record.public_send(@association_name)
  end

  def association_loaded?(record)
    record.association(@association_name).loaded?
  end
end
