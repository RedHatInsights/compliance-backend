class RecordLoader < GraphQL::Batch::Loader
  def initialize(model, column: model.primary_key, where: nil, order: nil, includes: nil)
    @model = model
    @column = column.to_s
    @column_type = model.type_for_attribute(@column)
    @where = where
    @order = order
    @includes = includes
  end

  def load(key)
    super(@column_type.cast(key))
  end

  def perform(keys)
    query(keys).each { |record| fulfill(record.public_send(@column), record) }
    keys.each { |key| fulfill(key, nil) unless fulfilled?(key) }
  end

  private

  def query(keys)
    scope = @model
    scope = scope.where(@where) if @where.present?
    scope = scope.order(@order) if @order.present?
    scope = scope.includes(@includes) if @includes.present?
    scope.where(@column => keys)
  end
end
