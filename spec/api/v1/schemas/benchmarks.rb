# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module Benchmarks
        BENCHMARK = {
          type: 'object',
          required: %w[ref_id title version],
          properties: {
            ref_id: {
              type: 'string',
              example: 'xccdf_org.ssgproject.content_benchmark_RHEL-7'
            },
            title: {
              type: 'string',
              example: 'Guide to the Secure Configuration of Red Hat '\
              'Enterprise Linux 7'
            },
            version: {
              type: 'string',
              example: '0.1.46'
            },
            description: {
              type: 'string'
            }
          }
        }.freeze
      end
    end
  end
end
