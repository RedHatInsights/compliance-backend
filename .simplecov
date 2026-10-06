# frozen_string_literal: true

SimpleCov.skip 'config'
SimpleCov.skip 'db'
SimpleCov.skip 'spec'
SimpleCov.skip 'test'

SimpleCov.group 'Consumers', 'app/consumers'
SimpleCov.group 'Controllers', 'app/controllers'
SimpleCov.group 'Jobs', 'app/jobs'
SimpleCov.group 'Models', 'app/models'
SimpleCov.group 'Policies', 'app/policies'
SimpleCov.group 'Serializers', 'app/serializers'
SimpleCov.group 'Services', 'app/services'
