require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RecipeMemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.i18n.default_locale = :ja
    config.time_zone = "Tokyo"

    # Serve attachments through the app instead of redirecting to a signed URL.
    # The redirect is cached for exactly as long as the URL it points at stays
    # valid, so reloading a page near that boundary hands the browser a URL that
    # has already expired and the image breaks. Proxying has no expiry, and on
    # the Disk service it also halves the requests, since the redirect target is
    # another Rails route anyway.
    config.active_storage.resolve_model_to_route = :rails_storage_proxy
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
