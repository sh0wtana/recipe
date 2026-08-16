require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Below md, so the dock is on test. This app is mobile-first for one-handed
  # use in a kitchen.
  #
  # 500 is Chrome's minimum window width. Ask for less and it discards the whole
  # request, height included, and falls back to 500x667. That is why asking for
  # a 375-wide, 2500-tall window silently produced a viewport that scrolls.
  #
  # The height is what keeps clicks landing. WebDriver scrolls a target only
  # just into view, which parks it against an edge, and those edges belong to
  # the fixed dock and the sticky header. They swallow the click and the test
  # fails with no error anywhere. Nothing scrolls when every page already fits.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 500, 2500 ]

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
