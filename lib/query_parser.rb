# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module API
    module Common
      # Query parser that can handle insights-flavored tags
      class QueryParser < ::SimpleDelegator
        TAG_RIGHT_RE = %r{^([^\/]+)\/([^\=]+)(\=(.+))?}.freeze

        def parse_nested_query(query_string, delimiter)
          # Decode the params with the default parser coming from Rack
          params = super

          # Override the parsed tags with our parsed version
          if params['tags']
            tags = parse_tags(query_string)
            params['tags'] = tags
          end

          params
        end

        private

        def parse_tags(query)
          return [] if query.empty?

          query.b.each_line('&').map do |string|
            left, _, right = string.chomp('&').partition('=')

            next unless left == 'tags'

            parse_tag(right)
          end.compact
        end

        def parse_tag(tag)
          namespace, key, _, value = tag.scan(TAG_RIGHT_RE).first

          return nil if namespace.nil? || key.nil?

          {
            namespace: decode_value(namespace),
            key: decode_value(key),
            value: value && decode_value(value)
          }
        end

        def decode_value(str)
          str.gsub(/\+|%\h\h/, URI::TBLDECWWWCOMP_)
             .force_encoding(Encoding::UTF_8)
             .scrub
        end
      end
    end
  end
end
