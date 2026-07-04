allowed_origins = ENV.fetch("ALLOWED_ORIGINS", "http://localhost:5173").split(",")

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :options]
  end
end