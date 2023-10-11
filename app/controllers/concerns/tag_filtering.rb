# frozen_string_literal: true

# Concern to support filtering by tags
module TagFiltering
  extend ActiveSupport::Concern

  TAG_RIGHT_RE = %r{^([^\/]+)\/([^\=]+)(\=(.+))?}

  included do
    def parse_tags(tags = [])
      tags.map { |tag| parse_tag(tag) }.compact
    end

    private

    def parse_tag(tag)
      namespace, key, _, value = tag.scan(TAG_RIGHT_RE).first

      return nil if namespace.nil? || key.nil?

      {
        namespace: unescape(namespace),
        key: unescape(key),
        value: value && unescape(value)
      }
    rescue ArgumentError
      raise ::Exceptions::InvalidTagEncoding
    end
  end

  def unescape(field)
    raise ArgumentError if field.match('\u0000')

    Rack::Utils.unescape(field)
  end

  def self.tags_supported?(resource)
    resource.taggable?
  end
end
