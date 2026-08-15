class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Pagy ships its own i18n, defaults to English, and keeps the locale in
  # Thread.current — so setting it at boot would only reach the booting thread.
  before_action { Pagy::I18n.locale = I18n.locale.to_s }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
