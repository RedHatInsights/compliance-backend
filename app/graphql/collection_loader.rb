# frozen_string_literal: true

# Class to batch collection loading, it heavily relies on cached and preloaded AR
# objects when querying individual entities in GraphQL. The preloader is used to
# load all child associations at once on a single or multiple model and then call
# their accessor when all the data is loaded into the preload-cache. This way we
# can prevent some N+1 queries from happening by just simply using this construct.
class CollectionLoader < GraphQL::Batch::Loader
  def initialize(model, association_name, *scopes, where: nil)
    @model = model
    @association_name = association_name
    @where = where
    @scopes = scopes
    validate
  end

  def load(record)
    unless record.is_a?(@model)
      raise TypeError, "#{@model} loader can't load association for #{record.class}"
    end

    # When the association is in the preload-cache, return it in a promise
    if association_loaded?(record)
      return Promise.resolve(read_association(record))
    end

    # Fall back to the preloader if the association is not loaded yet
    super
  end

  def perform(records)
    preload_association(records)
    records = records.where(@where) if @where.present?
    # Fulfill the promises after the associations are preloaded
    records.each { |record| fulfill(record, read_association(record)) }
  end

  private

  # The preloader accepts a chain of scopes and merges them with the association to
  # be preloaded. This way we can call a set of named scopes on the associations and
  # avoid making nested batch loads that can cause memory issues on a larger scale.
  def build_scope
    return nil if @scopes.empty?

    # Iterate through the available scopes and chain them to the association_class
    association_class
    scope = @scopes.reduce(association_class) do |acc, scope_name|
      acc.public_send(scope_name)
    end

    # If there are explicit selects defined, make sure that "base".* is also among them
    scope.select_values.any? ? scope.select(association_class.arel_table[Arel.star]) : scope
  end

  def validate
    raise ArgumentError, "No association #{@association_name} on #{@model}" if association_class.nil?
    raise ArgumentError, "Undefined scope #{@scope} on #{association_class}" unless valid_scopes?
  end

  def valid_scopes?
    @scopes.all? { |scope| association_class.respond_to?(scope) }
  end

  # The preloader is an internal-only class provided by rails, so using it is not
  # the best on a longer term. However, at the moment, there is no alternative and
  # it is the recommended solution by the authors of the GraphQL::Batch::Loader.
  #
  # There's a ticket about it on their GH, but so far it's unresolved:
  # https://github.com/Shopify/graphql-batch/issues/132
  def preload_association(records)
    ::ActiveRecord::Associations::Preloader.new(
      records: records, associations: @association_name, scope: build_scope
    ).call
  end

  def read_association(record)
    record.public_send(@association_name)
  end

  def association_loaded?(record)
    record.association(@association_name).loaded?
  end

  def association_class
    @model.reflect_on_association(@association_name)&.class_name&.safe_constantize
  end
end
