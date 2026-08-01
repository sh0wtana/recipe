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

  # The form submits no tag field yet (#13 adds it), so an edit must leave the
  # existing tags alone rather than clearing them.
  test "update without tag names leaves the tags alone" do
    assert_no_difference "RecipeTag.count" do
      patch recipe_path(@recipe), params: { recipe: { title: "からあげ（改）" } }
    end

    assert_equal %w[和食 豚肉].sort, @recipe.reload.tags.map(&:name).sort
  end

  test "update with a blank title re-renders the form" do
    assert_no_changes -> { @recipe.reload.title } do
      patch recipe_path(@recipe), params: { recipe: { title: "" } }
    end

    assert_response :unprocessable_content
  end

  test "destroy" do
    assert_difference "Recipe.count", -1 do
      delete recipe_path(@recipe)
    end

    assert_redirected_to recipes_path
  end
end
