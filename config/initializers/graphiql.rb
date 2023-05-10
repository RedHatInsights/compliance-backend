if Rails.env.development?
  GraphiQL::Rails.config.headers['X-RH-IDENTITY'] = -> (_context) { ENV['X_RH_IDENTITY'] }
end
