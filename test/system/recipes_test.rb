require "application_system_test_case"

class RecipesTest < ApplicationSystemTestCase
  setup do
    @recipe = recipes(:karaage)

    sign_in_as users(:one)
  end

  # The project's first system test. Until this passes, nothing else in the
  # browser is worth debugging.
  test "signing in lands on the recipe list" do
    assert_selector "h1", text: I18n.t("recipes.index.title")
  end
end
