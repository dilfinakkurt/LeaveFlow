require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LeaveFlow
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Autoload lib directory
    config.autoload_lib(ignore: %w[assets tasks])

    # Time zone configuration
    config.time_zone = "UTC"
  end
end
