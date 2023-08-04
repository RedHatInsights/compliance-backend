# frozen_string_literal: true

SimpleCov.start do
  add_filter 'config'
  add_filter 'db'
  add_filter 'spec'
  add_filter 'test'

  add_group 'Consumers', 'app/consumers'
  add_group 'Controllers', 'app/controllers'
  add_group 'GraphQL', 'app/graphql'
  add_group 'Jobs', 'app/jobs'
  add_group 'Models', 'app/models'
  add_group 'Policies', 'app/policies'
  add_group 'Serializers', 'app/serializers'
  add_group 'Services', 'app/services'
end
