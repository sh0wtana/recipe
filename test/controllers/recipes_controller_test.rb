require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @recipe = recipes(:karaage)
    @others_recipe = recipes(:miso_soup) # belongs to users(:two)

    sign_in_as(@user)
  end

  # Ownership is the whole authorization model — there is no policy layer behind
  # it. Each verb gets its own test so a single unscoped query cannot slip through.

  test "show another user's recipe returns 404" do
    get recipe_path(@others_recipe)

    assert_response :not_found
  end

  test "edit another user's recipe returns 404" do
    get edit_recipe_path(@others_recipe)

    assert_response :not_found
  end

  test "update another user's recipe returns 404 and changes nothing" do
    assert_no_changes -> { @others_recipe.reload.title } do
      patch recipe_path(@others_recipe), params: { recipe: { title: "乗っ取り" } }

      assert_response :not_found
    end
  end

  test "destroy another user's recipe returns 404 and deletes nothing" do
    assert_no_difference "Recipe.count" do
      delete recipe_path(@others_recipe)

      assert_response :not_found
    end
  end

  test "index lists only the signed-in user's recipes" do
    get recipes_path

    assert_response :success
    assert_select "a", text: @recipe.title
    assert_select "a", text: @others_recipe.title, count: 0
  end

  test "index requires authentication" do
    sign_out

    get recipes_path

    assert_redirected_to new_session_path
  end

  test "show" do
    get recipe_path(@recipe)

    assert_response :success
  end

  test "new" do
    get new_recipe_path

    assert_response :success
  end

  test "edit" do
    get edit_recipe_path(@recipe)

    assert_response :success
  end

  test "create" do
    assert_difference "Recipe.count", 1 do
      post recipes_path, params: { recipe: { title: "肉じゃが", description: "母の味",
                                             servings: "4人分", tips: "落とし蓋をする" } }
    end

    recipe = Recipe.last

    assert_equal @user, recipe.user
    assert_redirected_to recipe_path(recipe)
  end

  # Index-keyed hashes, because that is the shape fields_for actually submits.
  test "create with nested ingredients and steps" do
    post recipes_path, params: { recipe: {
      title: "肉じゃが",
      ingredients_attributes: { "0" => { name: "じゃがいも", amount: "3個", position: 0 } },
      steps_attributes: { "0" => { body: "材料を切る", position: 0 } } } }

    recipe = Recipe.last

    assert_equal [ "じゃがいも" ], recipe.ingredients.map(&:name)
    assert_equal [ "材料を切る" ], recipe.steps.map(&:body)
  end

  test "create with tag names creates tags owned by the signed-in user" do
    post recipes_path, params: { recipe: { title: "肉じゃが", tag_names: [ "和食", "煮物" ] } }

    recipe = Recipe.last

    assert_equal %w[和食 煮物].sort, recipe.tags.map(&:name).sort
    assert_equal [ @user ], recipe.tags.map(&:user).uniq
  end

  test "create with a blank title re-renders the form" do
    assert_no_difference "Recipe.count" do
      post recipes_path, params: { recipe: { title: "" } }
    end

    assert_response :unprocessable_content
  end

  test "update" do
    patch recipe_path(@recipe), params: { recipe: { title: "からあげ（改）" } }

    assert_equal "からあげ（改）", @recipe.reload.title
    assert_redirected_to recipe_path(@recipe)
  end

  # Requests that never mention tags at all still exist, so silence has to go on
  # meaning "leave them alone" rather than "clear them".
  test "update without tag names leaves the tags alone" do
    assert_no_difference "RecipeTag.count" do
      patch recipe_path(@recipe), params: { recipe: { title: "からあげ（改）" } }
    end

    assert_equal %w[和食 豚肉].sort, @recipe.reload.tags.map(&:name).sort
  end

  # Every box unticked and the new-tag field left empty. It reaches here as
  # [ "" ] and has to survive the permit list to clear anything.
  test "update with only the empty new-tag field clears the tags" do
    assert_difference "RecipeTag.count", -2 do
      patch recipe_path(@recipe), params: { recipe: { title: @recipe.title, tag_names: [ "" ] } }
    end

    assert_empty @recipe.reload.tags
  end

  test "update ticks and unticks tags in one save" do
    patch recipe_path(@recipe), params: {
      recipe: { title: @recipe.title, tag_names: [ "", "和食", "作り置き", "揚げ物" ] } }

    assert_equal %w[作り置き 和食 揚げ物].sort, @recipe.reload.tags.map(&:name).sort
  end

  test "update with a blank title re-renders the form" do
    assert_no_changes -> { @recipe.reload.title } do
      patch recipe_path(@recipe), params: { recipe: { title: "" } }
    end

    assert_response :unprocessable_content
  end

  # A failed save does not undo the destruction mark, so the re-rendered form
  # still carries it — which is what lets the editor keep the row hidden.
  test "update with a blank title re-renders a row still flagged for destruction" do
    chicken, soy_sauce, ginger = @recipe.ingredients.to_a

    assert_no_changes -> { @recipe.reload.title } do
      patch recipe_path(@recipe), params: { recipe: {
        title: "",
        ingredients_attributes: {
          "0" => { id: chicken.id, name: chicken.name, amount: chicken.amount, position: 0 },
          "1" => { id: soy_sauce.id, _destroy: "1" },
          "2" => { id: ginger.id, name: ginger.name, amount: ginger.amount, position: 1 } } } }
    end

    assert_response :unprocessable_content
    assert_select "#ingredient-fields input[name='recipe[ingredients_attributes][1][id]'][value=?]", soy_sauce.id.to_s
    assert_select "#ingredient-fields input[name='recipe[ingredients_attributes][1][_destroy]'][value=?]", "true"
  end

  # The shape the editor submits after a delete: the removed row carries
  # _destroy, the survivors carry positions renumbered by DOM order.
  test "update destroys a row marked _destroy and stores the renumbered positions" do
    chicken, soy_sauce, ginger = @recipe.ingredients.to_a

    patch recipe_path(@recipe), params: { recipe: {
      title: @recipe.title,
      ingredients_attributes: {
        "0" => { id: chicken.id, name: chicken.name, amount: chicken.amount, position: 0 },
        "1" => { id: soy_sauce.id, _destroy: "1" },
        "2" => { id: ginger.id, name: ginger.name, amount: ginger.amount, position: 1 },
        "1754821093117" => { name: "にんにく", amount: "1片", position: 2 } } } }

    assert_redirected_to recipe_path(@recipe)
    assert_not Ingredient.exists?(soy_sauce.id)
    assert_equal [ "鶏もも肉", "しょうが", "にんにく" ], @recipe.reload.ingredients.map(&:name)
    assert_equal [ 0, 1, 2 ], @recipe.ingredients.map(&:position)
  end

  # _destroy is here because the real form always sends it. Without it the test
  # would still pass if BLANK_ROW stopped ignoring _destroy, while the form broke.
  test "update ignores a row the user added and left empty" do
    patch recipe_path(@recipe), params: { recipe: {
      title: @recipe.title,
      ingredients_attributes: { "1754821093117" => { name: "", amount: "", position: 3, _destroy: "false" } } } }

    assert_redirected_to recipe_path(@recipe)
    assert_equal 3, @recipe.reload.ingredients.count
  end

  # remove() has no branch guarding the last row, and nothing validates that a
  # recipe has any ingredients. Deleting them all has to be a legal save.
  test "update accepts a recipe whose rows were all deleted" do
    patch recipe_path(@recipe), params: { recipe: {
      title: @recipe.title,
      ingredients_attributes: @recipe.ingredients.each_with_index.to_h { |ingredient, index|
        [ index.to_s, { id: ingredient.id, _destroy: "1" } ]
      } } }

    assert_redirected_to recipe_path(@recipe)
    assert_empty @recipe.reload.ingredients
  end

  test "destroy" do
    assert_difference "Recipe.count", -1 do
      delete recipe_path(@recipe)
    end

    assert_redirected_to recipes_path
  end
end
