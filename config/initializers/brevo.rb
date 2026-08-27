require Rails.root.join("lib/brevo_delivery_method").to_s

Brevo.configure do |config|
  config.api_key["api-key"] = ENV["BREVO_API_KEY"]
end

ActionMailer::Base.add_delivery_method :brevo, BrevoDeliveryMethod
