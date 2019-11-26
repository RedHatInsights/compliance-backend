class CollectionLoader < GraphQL::Batch::Loader
  def initialize(model, association_name, extra_method=nil)
    @model = model
    @association_name = association_name
    @extra_method = extra_method
    validate
  end

  def load(record)
    raise TypeError, "#{@model} loader can't load association for #{record.class}" unless record.is_a?(@model)
    return Promise.resolve(read_association(record)) if association_loaded?(record)
    super
  end

  def perform(records)
    preload_association(records)
    records.each { |record| fulfill(record, read_association(record)) }
  end

  private

  def validate
    unless @model.reflect_on_association(@association_name)
      raise ArgumentError, "No association #{@association_name} on #{@model}"
    end
  end

  def preload_association(records)
    ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name)
  end

  def read_association(record)
    if @extra_method.present?
      record.public_send(@extra_method)
    else
      record.public_send(@association_name)
    end
  end

  def association_loaded?(record)
    record.association(@association_name).loaded?
  end
end
