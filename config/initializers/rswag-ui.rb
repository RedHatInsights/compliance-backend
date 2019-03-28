Rswag::Ui.configure do |c|
  c.swagger_endpoint "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/v1/openapi.json",
    'Compliance API V1 Docs'
end
