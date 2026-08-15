require "application_system_test_case"

class RecipesTest < ApplicationSystemTestCase
  setup do
    @recipe = recipes(:karaage)
  end

  # The only test that goes through the login form. The others take the cookie,
  # so a click swallowed there cannot fail them.
  test "signing in lands on the recipe list" do
    sign_in_as users(:one)

    assert_selector "h1", text: I18n.t("recipes.index.title")
  end

  test "adds and removes ingredient and step rows" do
    sign_in_through_cookie users(:one)

    visit edit_recipe_path(@recipe)

    assert_selector ingredient_row, count: 3

    click_on I18n.t("recipes.form.add_ingredient")
    assert_selector ingredient_row, count: 4

    within all(ingredient_row).last do
      find("input[name$='[name]']").set("にんにく")
      find("input[name$='[amount]']").set("1片")
    end

    ingredient_row_named("醤油").click_on I18n.t("recipes.ingredient_fields.remove")
    assert_selector ingredient_row, count: 3

    click_on I18n.t("recipes.form.add_step")
    assert_selector step_row, count: 3

    within all(step_row).last do
      find("textarea[name$='[body]']").set("にんにくを加えて和える")
    end

    click_on I18n.t("helpers.submit.update")

    # Waits for the redirect. all() does not wait, so asserting on the lists
    # first would race the navigation.
    assert_selector "h1", text: @recipe.title

    assert_equal [ "鶏もも肉 300g", "しょうが", "にんにく 1片" ],
      all("#ingredients li").map { |li| li.text.squish }
    assert_equal 3, all("#steps li").count

    # The delete left a gap at position 1; renumber closed it.
    assert_equal [ 0, 1, 2 ], @recipe.reload.ingredients.map(&:position)
  end

  # Only a browser shows whether connect() actually hides the re-rendered row.
  # What the server received is already covered at the integration level.
  test "a deleted row stays hidden after a failed save" do
    sign_in_through_cookie users(:one)

    visit edit_recipe_path(@recipe)

    ingredient_row_named("醤油").click_on I18n.t("recipes.ingredient_fields.remove")
    assert_selector ingredient_row, count: 2

    fill_in Recipe.human_attribute_name(:title), with: ""
    click_on I18n.t("helpers.submit.update")

    assert_selector "h1", text: I18n.t("recipes.edit.title")
    assert_selector ingredient_row, count: 2
  end

  private
    # Matching the row target, so the controller and the test agree on what a
    # row is. <template> contents are invisible to querySelectorAll.
    def ingredient_row = "#ingredient-fields [data-nested-rows-target='row']"
    def step_row       = "#step-fields [data-nested-rows-target='row']"

    # The nested fields have no labels yet (#15), so rows are addressed by the
    # suffix of the name attribute Rails generates.
    def ingredient_row_named(name)
      all(ingredient_row).find { |row| row.find("input[name$='[name]']").value == name } ||
        raise("no ingredient row named #{name.inspect}")
    end
end
