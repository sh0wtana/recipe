require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # An iPhone SE — the narrowest phone still in use. Fits here means fits
  # everywhere, and this app is mobile-first for one-handed use in a kitchen.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 667 ]

  # A real browser never sees a cookie stuffed into the test process, so this
  # signs in for real. Matching by placeholder: that view has no labels.
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
