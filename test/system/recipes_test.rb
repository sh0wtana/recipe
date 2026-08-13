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

  test "adds and removes ingredient and step rows" do
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

  # Rails marks a row for destruction while assigning attributes, before the
  # save is attempted, so a failed save re-renders it — still flagged. Only a
  # browser can show whether connect() actually hides it; the params the
  # server received are already covered at the integration level.
  test "a deleted row stays hidden after a failed save" do
    visit edit_recipe_path(@recipe)

    ingredient_row_named("醤油").click_on I18n.t("recipes.ingredient_fields.remove")
    assert_selector ingredient_row, count: 2

    fill_in Recipe.human_attribute_name(:title), with: ""
    click_on I18n.t("helpers.submit.update")

    assert_selector "h1", text: I18n.t("recipes.edit.title")
    assert_selector ingredient_row, count: 2
  end

  private
    # A row carries the row target — the controller defines it the same way.
    def ingredient_row = "#ingredient-fields [data-nested-rows-target='list'] > div"
    def step_row       = "#step-fields [data-nested-rows-target='list'] > div"

    # The nested fields have no labels yet (#15), so rows are addressed by the
    # suffix of the name attribute Rails generates.
    def ingredient_row_named(name)
      all(ingredient_row).find { |row| row.find("input[name$='[name]']").value == name } ||
        raise("no ingredient row named #{name.inspect}")
    end
end
