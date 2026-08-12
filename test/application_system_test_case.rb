require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # An iPhone SE, the narrowest phone still in use. The app is mobile-first for
  # one-handed use in a kitchen, and screen size is what decides whether Capybara
  # considers an element inside the viewport when it clicks.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 667 ]

  # Shadows SessionTestHelper#sign_in_as, which test_helper mixes into every
  # integration test and which SystemTestCase therefore inherits. That version
  # stuffs a cookie into the test process, where a real browser never sees it —
  # it would silently authenticate nobody.
  #
  # Matching by placeholder because sessions/new.html.erb has no labels.
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in I18n.t("sessions.new.email_placeholder"), with: user.email_address
    fill_in I18n.t("sessions.new.password_placeholder"), with: password
    click_on I18n.t("sessions.new.submit")
  end
end
