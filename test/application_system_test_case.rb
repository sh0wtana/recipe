require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # An iPhone SE — the narrowest phone still in use. Fits here means fits
  # everywhere, and this app is mobile-first for one-handed use in a kitchen.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 667 ]

  # Hands the browser the same signed cookie the app would set, so it sends it
  # like any other. Tests that are not about signing in use this, because a
  # click swallowed on the login page used to fail all of them (#36).
  def sign_in_through_cookie(user)
    visit root_path # a cookie cannot be set before there is a document

    jar = ActionDispatch::TestRequest.create.cookie_jar
    jar.signed[:session_id] = user.sessions.create!.id

    page.driver.browser.manage.add_cookie(name: "session_id", value: jar[:session_id], path: "/")
  end

  # Drives the real form, and exactly one test should. Matching by placeholder:
  # that view has no labels.
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in I18n.t("sessions.new.email_placeholder"), with: user.email_address
    fill_in I18n.t("sessions.new.password_placeholder"), with: password
    click_on I18n.t("sessions.new.submit")

    # click_on returns when the click dispatches, not when Turbo's POST lands.
    # Without this wait a following `visit` races it and ends up back on login.
    assert_current_path root_path
  end
end
