require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  test "signed in pages render the header" do
    sign_in_as(User.take)

    get root_path

    assert_select "header a[href=?]", new_recipe_path
  end

  test "the header offers sign out" do
    sign_in_as(User.take)

    get root_path

    assert_select "header form[action=?]", session_path do
      assert_select "input[name=?][value=?]", "_method", "delete"
    end
  end

  # The header renders for branding, but a visitor who is not signed in must not
  # be offered a sign-out button or a link to the editor.
  test "the sign in page shows the header without the signed in actions" do
    get new_session_path

    assert_response :success
    assert_select "header"
    assert_select "header a[href=?]", new_recipe_path, false
    assert_select "header form[action=?]", session_path, false
  end

  test "a flash set before a redirect renders in the layout" do
    user = User.take

    post session_path, params: { email_address: user.email_address, password: "wrong" }
    follow_redirect!

    assert_select "#alert", text: I18n.t("sessions.create.invalid_credentials")
  end
end
