# frozen_string_literal: true

# Populate Settings from environment variables when Clowder is not available. (In Foreman/Satellite)
# When ACG_CONFIG is set, ClowderCommonRuby's engine handles this instead.

require 'clowder-common-ruby'

if !ClowderCommonRuby::Config.clowder_enabled? && defined?(Settings)
  config = {
    'logging' => {
      'type'      => ENV['LOGGING_TYPE'],
      'region'    => ENV['LOGGING_REGION'],
      'log_group' => ENV['LOGGING_LOG_GROUP'],
      'credentials' => {
        'access_key_id'     => ENV['LOGGING_ACCESS_KEY_ID'],
        'secret_access_key' => ENV['LOGGING_SECRET_ACCESS_KEY']
      }
    },
    'kafka' => {
      'brokers'           => ENV.fetch('KAFKA_BROKERS', ''),
      'security_protocol' => ENV.fetch('KAFKA_SECURITY_PROTOCOL', 'plaintext'),
      'sasl_username'     => ENV['KAFKA_SASL_USERNAME'],
      'sasl_password'     => ENV['KAFKA_SASL_PASSWORD'],
      'sasl_mechanism'    => ENV['KAFKA_SASL_MECHANISM'],
      'ssl_ca_location'   => ENV['KAFKA_SSL_CA_LOCATION'],
      'topics' => {
        'inventory_events'               => ENV['KAFKA_TOPIC_INVENTORY_EVENTS'],
        'upload_compliance'              => ENV['KAFKA_TOPIC_UPLOAD_COMPLIANCE'],
        'payload_status'                 => ENV['KAFKA_TOPIC_PAYLOAD_STATUS'],
        'notifications_ingress'          => ENV['KAFKA_TOPIC_NOTIFICATIONS_INGRESS'],
        'remediation_updates_compliance' => ENV['KAFKA_TOPIC_REMEDIATION_UPDATES'],
        'inventory_host_apps'            => ENV['KAFKA_TOPIC_INVENTORY_HOST_APPS']
      }
    },
    'redis' => {
      'url'            => ENV['REDIS_URL'],
      'password'       => ENV['REDIS_PASSWORD'],
      'ssl'            => ENV.fetch('REDIS_SSL', 'false'),
      'cache_hostname' => ENV['REDIS_CACHE_HOSTNAME'],
      'cache_port'     => ENV['REDIS_CACHE_PORT'],
      'cache_password' => ENV['REDIS_CACHE_PASSWORD']
    },
    'endpoints' => {
      'rbac' => {
        'scheme' => ENV['RBAC_SCHEME'],
        'host'   => ENV['RBAC_HOST'],
        'url'    => ENV['RBAC_URL']
      },
      'host_inventory' => {
        'url' => ENV['HOST_INVENTORY_URL']
      }
    },
    'private_endpoints' => {
      'compliance_ssg' => {
        'url' => ENV['COMPLIANCE_SSG_URL']
      }
    },
    'platform_basic_auth_username' => ENV['PLATFORM_BASIC_AUTH_USERNAME'],
    'platform_basic_auth_password' => ENV['PLATFORM_BASIC_AUTH_PASSWORD']
  }

  Settings.add_source!(config)
  Settings.reload!
end
