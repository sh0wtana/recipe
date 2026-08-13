require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # An iPhone SE, the narrowest phone still in use. The app is mobile-first for
  # one-handed use in a kitchen, and screen size is what decides whether Capybara
  # considers an element inside the viewport when it clicks.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 667 ]

  # System tests drive a real browser, so authentication has to go through the
  # actual sign-in form rather than stuffing a session cookie into the test
  # process. Matching by placeholder because sessions/new.html.erb has no labels.
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in I18n.t("sessions.new.email_placeholder"), with: user.email_address
    fill_in I18n.t("sessions.new.password_placeholder"), with: password
    click_on I18n.t("sessions.new.submit")

    # The login form submits through Turbo, so click_on returns as soon as the
    # click event dispatches, before the POST resolves. A caller that follows
    # sign_in_as with a hard `visit` (a real navigation, not a waiting Capybara
    # query) can otherwise fire it before the browser has the session cookie
    # and land back on the login page.
    assert_current_path root_path
  end
end
