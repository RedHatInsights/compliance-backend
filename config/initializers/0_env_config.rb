# frozen_string_literal: true

# Populate Settings from environment variables when Clowder is not available. (In Foreman/Satellite)
# When ACG_CONFIG is set, ClowderCommonRuby's engine handles this instead.

require 'clowder-common-ruby'

if !ClowderCommonRuby::Config.clowder_enabled? && defined?(Settings)
  config = {
    'kafka' => {
      'brokers'           => ENV.fetch('KAFKA_BROKERS', 'kafka:9092'),
      'security_protocol' => ENV.fetch('KAFKA_SECURITY_PROTOCOL', 'plaintext'),
      'topics' => {
        'inventory_events'               => ENV.fetch('KAFKA_TOPIC_INVENTORY_EVENTS', 'platform.inventory.events'),
        'upload_compliance'              => ENV.fetch('KAFKA_TOPIC_UPLOAD_COMPLIANCE', 'platform.upload.compliance'),
        'payload_status'                 => ENV.fetch('KAFKA_TOPIC_PAYLOAD_STATUS', 'platform.payload-status'),
        'notifications_ingress'          => ENV.fetch('KAFKA_TOPIC_NOTIFICATIONS_INGRESS', 'platform.notifications.ingress'),
        'remediation_updates_compliance' => ENV.fetch('KAFKA_TOPIC_REMEDIATION_UPDATES', 'platform.remediation-updates.compliance'),
        'inventory_host_apps'            => ENV.fetch('KAFKA_TOPIC_INVENTORY_HOST_APPS', 'platform.inventory.host-apps')
      }
    },
    'redis' => {
      'url'            => ENV.fetch('REDIS_URL', 'redis://redis:6379'),
      'password'       => ENV['REDIS_PASSWORD'],
      'ssl'            => ENV.fetch('REDIS_SSL', 'false'),
      'cache_hostname' => ENV.fetch('REDIS_CACHE_HOSTNAME', 'redis'),
      'cache_port'     => ENV.fetch('REDIS_CACHE_PORT', '6379'),
      'cache_password' => ENV['REDIS_CACHE_PASSWORD']
    },
    'endpoints' => {
      'host_inventory' => {
        'url' => ENV.fetch('HOST_INVENTORY_URL', 'http://inventory-web:8081')
      }
    },
    'private_endpoints' => {
      'compliance_ssg' => {
        'url' => ENV.fetch('COMPLIANCE_SSG_URL', 'http://compliance-ssg:8088')
      }
    },
    'disable_rbac' => ENV.fetch('DISABLE_RBAC', 'true')
  }

  Settings.add_source!(config)
  Settings.reload!
end
