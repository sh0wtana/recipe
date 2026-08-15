require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  # sign_in_as clicks the submit button; this test presses Enter instead to verify
  # that native implicit form submission survived the Enter-key handler refactor.
  test "Enter in the password field still signs in" do
    visit new_session_path

    fill_in I18n.t("sessions.new.email_placeholder"), with: users(:one).email_address
    fill_in I18n.t("sessions.new.password_placeholder"), with: "password"
    find_field(I18n.t("sessions.new.password_placeholder")).send_keys(:enter)

    assert_current_path root_path
  end
end
