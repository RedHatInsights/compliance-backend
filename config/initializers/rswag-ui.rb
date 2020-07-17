Rswag::Ui.configure do |c|
  c.swagger_endpoint "#{Settings.path_prefix}/#{Settings.app_name}/v1/openapi.json",
    'Compliance API V1 Docs'
  c.swagger_endpoint "#{Settings.old_path_prefix}/#{Settings.app_name}/v1/openapi.json",
    'Compliance API V1 Docs'
end
