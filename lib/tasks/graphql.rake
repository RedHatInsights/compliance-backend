# frozen_string_literal: true

task dump_schema: :environment do
  schema_defn = Schema.to_definition
  schema_path = 'app/graphql/schema.graphql'
  Rails.root.join(schema_path).write(schema_defn)
  puts "Updated #{schema_path}"
end
