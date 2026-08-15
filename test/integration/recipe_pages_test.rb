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
  # Scoped to the list because the fieldset also holds a <template> of the same
  # partial, and assert_select counts its fields even though a browser wouldn't.
  test "edit renders the row hooks and a remove button for each ingredient" do
    get edit_recipe_path(@recipe)

    list = "#ingredient-fields [data-nested-rows-target=list]"
    assert_select "#{list} [data-nested-rows-target=row]", count: 3
    assert_select "#{list} input[type=hidden][data-position]", count: 3
    assert_select "#{list} input[type=hidden][data-destroy]", count: 3
    assert_select "#{list} button[type=button]", count: 3,
      text: I18n.t("recipes.ingredient_fields.remove")
  end

  test "edit renders the row hooks and a remove button for each step" do
    get edit_recipe_path(@recipe)

    list = "#step-fields [data-nested-rows-target=list]"
    assert_select "#{list} [data-nested-rows-target=row]", count: 2
    assert_select "#{list} input[type=hidden][data-position]", count: 2
    assert_select "#{list} input[type=hidden][data-destroy]", count: 2
    assert_select "#{list} button[type=button]", count: 2,
      text: I18n.t("recipes.step_fields.remove")
  end

  test "edit offers a checkbox for every tag the user owns, ticked for this recipe's" do
    @user.tags.create!(name: "デザート")

    get edit_recipe_path(@recipe)

    boxes = css_select("#tag-fields input[type=checkbox]")

    assert_equal %w[デザート 和食 豚肉].sort, boxes.map { |box| box[:value] }.sort
    assert_equal %w[和食 豚肉].sort,
      boxes.select { |box| box[:checked] }.map { |box| box[:value] }.sort
  end

  # The other user owns a tag of the same name, and it must not double up here.
  test "edit does not offer another user's tags" do
    get edit_recipe_path(@recipe)

    assert_select "#tag-fields input[type=checkbox][value=?]", "和食", count: 1
  end

  # HTML omits empty array params, so a form of nothing but checkboxes sends no
  # tag_names at all once they are all unticked. This field always submits.
  test "edit renders a new-tag field that submits even when left empty" do
    get edit_recipe_path(@recipe)

    assert_select "#tag-fields input[type=text][name='recipe[tag_names][]']", count: 1
  end

  # A name the user typed has no Tag row yet, so a list built from their tags
  # alone would drop it the moment the save is rejected.
  test "edit keeps a typed new tag after a rejected save" do
    patch recipe_path(@recipe), params: {
      recipe: { title: "", tag_names: [ "", "和食", "作り置き" ] } }

    assert_response :unprocessable_content
    assert_select "#tag-fields input[type=checkbox][value=?][checked]", "作り置き"
    assert_select "#tag-fields input[type=checkbox][value=?][checked]", "和食"
    assert_select "#tag-fields input[type=checkbox][value=?]:not([checked])", "豚肉"
  end
end
