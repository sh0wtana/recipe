require "application_system_test_case"

class RecipesTest < ApplicationSystemTestCase
  setup do
    @recipe = recipes(:karaage)

    sign_in_as users(:one)
  end

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

  # Only a browser shows whether connect() actually hides the re-rendered row.
  # What the server received is already covered at the integration level.
  test "a deleted row stays hidden after a failed save" do
    visit edit_recipe_path(@recipe)

    ingredient_row_named("醤油").click_on I18n.t("recipes.ingredient_fields.remove")
    assert_selector ingredient_row, count: 2

    fill_in Recipe.human_attribute_name(:title), with: ""
    click_on I18n.t("helpers.submit.update")

    assert_selector "h1", text: I18n.t("recipes.edit.title")
    assert_selector ingredient_row, count: 2
  end

  test "dragging a row by its handle saves the new order" do
    visit edit_recipe_path(@recipe)

    drag_row ingredient_row_named("しょうが"), onto: ingredient_row_named("鶏もも肉")
    drag_row all(step_row).first, onto: all(step_row).last

    click_on I18n.t("helpers.submit.update")

    assert_selector "h1", text: @recipe.title

    assert_equal [ "しょうが", "鶏もも肉 300g", "醤油 大さじ2" ],
      all("#ingredients li").map { |li| li.text.squish }
    assert_equal [ "170℃の油で4分ほど揚げる", "鶏肉を一口大に切り、調味料に30分漬ける" ],
      all("#steps li").map(&:text)
  end

  # A deleted row is only hidden, so Sortable still has it in the list. It is
  # renumber() that has to keep skipping it, or the saved positions get a gap.
  test "dragging after a delete still numbers the rows from zero" do
    visit edit_recipe_path(@recipe)

    ingredient_row_named("醤油").click_on I18n.t("recipes.ingredient_fields.remove")
    drag_row ingredient_row_named("しょうが"), onto: ingredient_row_named("鶏もも肉")

    click_on I18n.t("helpers.submit.update")

    assert_selector "h1", text: @recipe.title
    assert_equal %w[しょうが 鶏もも肉], @recipe.reload.ingredients.map(&:name)
    assert_equal [ 0, 1 ], @recipe.reload.ingredients.map(&:position)
  end

  test "Enter in the title does not save and leave the editor" do
    visit new_recipe_path

    fill_in Recipe.human_attribute_name(:title), with: "きんぴら"
    find_field(Recipe.human_attribute_name(:title)).send_keys(:enter)

    assert_current_path new_recipe_path
    assert_not Recipe.exists?(title: "きんぴら")
  end

  test "Enter in an ingredient field stays on the editor" do
    visit edit_recipe_path(@recipe)

    within(ingredient_row_named("醤油")) do
      find("input[name$='[amount]']").send_keys(:enter)
    end

    assert_current_path edit_recipe_path(@recipe)
    assert_selector ingredient_row, count: 3
  end

  test "Enter in a step body inserts a newline instead of submitting" do
    visit edit_recipe_path(@recipe)

    body_field = all(step_row).first.find("textarea[name$='[body]']")
    body_field.set("下味をつける\n強火で揚げる")

    assert_current_path edit_recipe_path(@recipe)
    assert_equal "下味をつける\n強火で揚げる", body_field.value
  end

  test "Enter still saves when the save button itself is focused" do
    visit edit_recipe_path(@recipe)

    find_button(I18n.t("helpers.submit.update")).send_keys(:enter)

    assert_selector "h1", text: @recipe.title
  end

  test "Enter in the search box still searches" do
    visit recipes_path

    fill_in I18n.t("recipes.index.search"), with: @recipe.title
    find_field(I18n.t("recipes.index.search")).send_keys(:enter)

    assert_selector "h1", text: I18n.t("recipes.index.title")
    assert_selector "#recipes", text: @recipe.title
    assert_selector "#clear-search"
  end

  test "picks a photo and saves it with the recipe" do
    visit new_recipe_path

    fill_in Recipe.human_attribute_name(:title), with: "肉じゃが"

    # make_visible: the input is sr-only, and Capybara refuses to attach to an
    # element it considers hidden.
    attach_file "recipe[photo]", file_fixture("dish.jpg"), make_visible: true

    assert_selector "[data-photo-preview-target='image'][src^='blob:']"

    click_on I18n.t("helpers.submit.create")

    assert_selector "h1", text: "肉じゃが"
    assert_predicate Recipe.find_by(title: "肉じゃが").photo, :attached?
  end

  # Headless Chrome cannot decode HEIF, which puts it in exactly the position a
  # desktop browser is in. The phone this app is used from previews it fine.
  test "names the file when the browser cannot preview it" do
    visit new_recipe_path

    attach_file "recipe[photo]", file_fixture("dish.heic"), make_visible: true

    assert_no_selector "[data-photo-preview-target='image']"
    assert_text "dish.heic"
  end

  test "removes the photo with the trash button" do
    @recipe.photo.attach(io: file_fixture("dish.jpg").open, filename: "dish.jpg", content_type: "image/jpeg")

    visit edit_recipe_path(@recipe)

    assert_selector "[data-photo-preview-target='image']"

    find("[data-photo-preview-target='button']").click

    assert_no_selector "[data-photo-preview-target='image']"

    click_on I18n.t("helpers.submit.update")

    assert_current_path recipe_path(@recipe)
    assert_not @recipe.reload.photo.attached?
  end

  private
    # Matching the row target, so the controller and the test agree on what a
    # row is. <template> contents are invisible to querySelectorAll.
    def ingredient_row = "#ingredient-fields [data-nested-rows-target='row']"
    def step_row       = "#step-fields [data-nested-rows-target='row']"

    # The nested fields have no labels yet (#15), so rows are addressed by the
    # suffix of the name attribute Rails generates.
    # Capybara's drag_to jumps straight from the handle to the target, and
    # SortableJS never sees a drag in that. The nudges either side of the move
    # are what start it and settle it. Their direction does not matter.
    def drag_row(row, onto:)
      page.driver.browser.action
        .click_and_hold(row.find("[data-handle]").native)
        .move_by(0, -8)
        .move_to(onto.native)
        .move_by(0, -8)
        .release
        .perform
    end

    def ingredient_row_named(name)
      all(ingredient_row).find { |row| row.find("input[name$='[name]']").value == name } ||
        raise("no ingredient row named #{name.inspect}")
    end
end
