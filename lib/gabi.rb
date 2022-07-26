# frozen_string_literal: true

# rubocop:disable Rails/Output

require 'faraday'

# Methods related to querying gabi
class Gabi
  BATCH_SIZE = 10_000

  def initialize(url:, token:)
    # "Safeguard" to only allow stage to be queried
    # raise ArgumentError unless url =~ /stage/

    @client = connection(url, token)
  end

  def seed(relation)
    raw_seed(relation.model, relation.to_sql)
  end

  def raw_seed(model, sql, &block)
    count = query(sql.sub(/SELECT (.*\.\*) FROM/, 'SELECT COUNT(*) FROM'))[1][0].to_i

    # return query(sql) if count < BATCH_SIZE

    puts "#{count} records will be queried in a batch of #{BATCH_SIZE}"

    (count.to_f / BATCH_SIZE).ceil.times.each do |idx|
      batch = fetch_batch(sql, idx, &block)
      # rubocop:disable Rails/SkipsModelValidations
      model.insert_all!(batch)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  private

  def parse_result(rows)
    columns = rows.shift
    rows.uniq.map do |row|
      row.each_with_index.each_with_object({}) do |(value, idx), obj|
        # Optional override of the colname using a block
        colname, value = block_given? ? yield(columns[idx], value) : [columns[idx], value]
        # Omit the column if the block returns `nil`
        next if colname.nil?

        obj[colname] = value
      end
    end
  end

  def fetch_batch(sql, idx, &block)
    batch = query(sql + " ORDER BY id LIMIT #{BATCH_SIZE} OFFSET #{idx * BATCH_SIZE}")
    parse_result(batch, &block)
  end

  def query(sql)
    puts sql
    @client.post('/query', { query: sql }.to_json)

    result = @client.post('/query', { query: sql }.to_json)
    JSON.parse(result.body)['result']
  end

  def connection(url, token)
    Faraday.new(url) do |f|
      f.response :raise_error
      f.adapter Faraday.default_adapter # this must be the last middleware
      f.ssl[:verify] = Rails.env.production?
      f.request :authorization, 'Bearer', token
      f.headers['Content-Type'] = 'application/json'
    end
  end
end
# rubocop:enable Rails/Output
