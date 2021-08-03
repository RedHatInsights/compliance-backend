# frozen_string_literal: true

# Concern to support filtering by tags
module TagFiltering
  extend ActiveSupport::Concern

  TAG_RIGHT_RE = %r{^([^\/]+)\/([^\=]+)(\=(.+))?}.freeze

  included do
    def parse_tags(tags = [])
      tags.map { |tag| parse_tag(tag) }.compact
    end

    private

    def parse_tag(tag)
      namespace, key, _, value = tag.scan(TAG_RIGHT_RE).first

      return nil if namespace.nil? || key.nil?

      {
        namespace: Rack::Utils.unescape(namespace),
        key: Rack::Utils.unescape(key),
        value: value && Rack::Utils.unescape(value)
      }
    end

    def decode_value(str)
      str.gsub(/\+|%\h\h/, URI::TBLDECWWWCOMP_)
         .force_encoding(Encoding::UTF_8)
         .scrub
    end
  end

  def self.tags_supported?(resource)
    resource.column_names.include?('tags')
  end
end
