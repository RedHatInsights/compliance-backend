Rswag::Ui.configure do |c|
  c.openapi_endpoint "#{Settings.path_prefix}/#{Settings.app_name}/v2/openapi.json",
    'Compliance API V2 Docs'
  c.openapi_endpoint "#{Settings.old_path_prefix}/#{Settings.app_name}/v2/openapi.json",
    'Compliance API V2 Docs'
end
