require "test_helper"

class RecipePagesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @recipe = recipes(:karaage)

    sign_in_as(@user)
  end

  test "index renders each recipe's tags as filter links" do
    get recipes_path

    assert_select "a[href=?]", recipes_path(tag: "和食"), text: "和食"
    assert_select "a[href=?]", recipes_path(tag: "豚肉"), text: "豚肉"
  end

  test "index shows when a recipe was created" do
    get recipes_path

    assert_select "time", text: I18n.l(@recipe.created_at, format: :long)
  end

  test "index says so when there are no recipes yet" do
    @user.recipes.destroy_all

    get recipes_path

    assert_select "p", text: I18n.t("recipes.index.empty")
  end

  test "show lists ingredients with their amounts in position order" do
    get recipe_path(@recipe)

    assert_equal [ "鶏もも肉 300g", "醤油 大さじ2", "しょうが" ],
      css_select("#ingredients li").map { |li| li.text.squish }
  end

  test "show numbers the steps in position order" do
    get recipe_path(@recipe)

    assert_select "ol#steps"
    assert_equal [ "鶏肉を一口大に切り、調味料に30分漬ける", "170℃の油で4分ほど揚げる" ],
      css_select("#steps li").map { |li| li.text.squish }
  end

  # Deleting cascades to ingredients, steps and tag joins, and there is no undo.
  test "show names the recipe when confirming a delete" do
    get recipe_path(@recipe)

    assert_select "form[data-turbo-confirm=?]",
      I18n.t("recipes.show.confirm_destroy", title: @recipe.title)
  end

  test "show omits the optional sections a recipe has not filled in" do
    @recipe.update!(description: "", servings: "", tips: "")

    get recipe_path(@recipe)

    assert_select "#description", false
    assert_select "#servings", false
    assert_select "#tips", false
  end

  # The Stimulus controller finds these by attribute, one of each per row.
  #
  # Scoped to the list, not just the fieldset: the fieldset also holds a
  # <template> for cloning new rows, built from this same partial so the
  # markup is never duplicated. A real browser never renders <template>
  # content, but assert_select's parser doesn't know that, so an unscoped
  # selector would double-count the template's own copy of these fields.
  test "edit renders the row hooks and a remove button for each ingredient" do
    get edit_recipe_path(@recipe)

    list = "#ingredient-fields [data-nested-rows-target=list]"
    assert_select "#{list} input[type=hidden][data-position]", count: 3
    assert_select "#{list} input[type=hidden][data-destroy]", count: 3
    assert_select "#{list} button[type=button]", count: 3,
      text: I18n.t("recipes.ingredient_fields.remove")
  end

  test "edit renders the row hooks and a remove button for each step" do
    get edit_recipe_path(@recipe)

    list = "#step-fields [data-nested-rows-target=list]"
    assert_select "#{list} input[type=hidden][data-position]", count: 2
    assert_select "#{list} input[type=hidden][data-destroy]", count: 2
    assert_select "#{list} button[type=button]", count: 2,
      text: I18n.t("recipes.step_fields.remove")
  end
end
