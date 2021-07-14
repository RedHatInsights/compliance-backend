require 'rack/request'
require 'query_parser'

Rack::Request::Env.class_eval do
  def query_parser
    Insights::API::Common::QueryParser.new(super)
  end
end
