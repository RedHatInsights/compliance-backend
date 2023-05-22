# frozen_string_literal: true

require 'test_helper'

module Insights
  module Api
    module Common
      module AdjustTags
        class MiddlewareTest < ActiveSupport::TestCase
          class DummyRack
            def call(env)
              env
            end
          end

          setup do
            @mw = Middleware.new(DummyRack.new)
          end

          test 'replaces tags= with tags[]=' do
            env = {
              'QUERY_STRING' => 'x=y&tags=foo&tags=bar',
              'REQUEST_URI' => 'http://localhost:3000/?x=y&tags=foo&tags=bar'
            }
            result = @mw.call(env)
            assert_equal result['QUERY_STRING'], 'x=y&tags[]=foo&tags[]=bar'
            assert_equal result['REQUEST_URI'], 'http://localhost:3000/?x=y&tags[]=foo&tags[]=bar'
          end

          test 'matches the query string only at the end of the uri' do
            env = {
              'QUERY_STRING' => 'x=y&tags=foo&tags=bar',
              'REQUEST_URI' => 'http://localhost:3000/tags=foo/?x=y&tags=foo&tags=bar'
            }
            result = @mw.call(env)
            assert_equal result['QUERY_STRING'], 'x=y&tags[]=foo&tags[]=bar'
            assert_equal result['REQUEST_URI'], 'http://localhost:3000/tags=foo/?x=y&tags[]=foo&tags[]=bar'
          end
        end
      end
    end
  end
end
