require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tag = tags(:washoku)
    @others_tag = tags(:two_washoku) # same name, belongs to users(:two)

    sign_in_as(@user)
  end

  # Ownership is the whole authorization model — there is no policy layer behind
  # it. Each verb gets its own test so a single unscoped query cannot slip through.

  test "edit another user's tag returns 404" do
    get edit_tag_path(@others_tag)

    assert_response :not_found
  end

  test "update another user's tag returns 404 and changes nothing" do
    assert_no_changes -> { @others_tag.reload.name } do
      patch tag_path(@others_tag), params: { tag: { name: "乗っ取り" } }

      assert_response :not_found
    end
  end

  test "destroy another user's tag returns 404 and deletes nothing" do
    assert_no_difference "Tag.count" do
      delete tag_path(@others_tag)

      assert_response :not_found
    end
  end

  test "index lists only the signed-in user's tags" do
    get tags_path

    assert_response :success
    assert_equal @user.tags.count, css_select("#tags li").count
  end

  test "index requires authentication" do
    sign_out

    get tags_path

    assert_redirected_to new_session_path
  end

  test "new" do
    get new_tag_path

    assert_response :success
  end

  test "edit" do
    get edit_tag_path(@tag)

    assert_response :success
  end

  test "create" do
    assert_difference "Tag.count", 1 do
      post tags_path, params: { tag: { name: "作り置き" } }
    end

    assert_equal @user, Tag.last.user
    assert_redirected_to tags_path
  end

  test "create with a blank name re-renders the form" do
    assert_no_difference "Tag.count" do
      post tags_path, params: { tag: { name: "" } }
    end

    assert_response :unprocessable_content
  end

  test "create with a name the user already has re-renders the form" do
    assert_no_difference "Tag.count" do
      post tags_path, params: { tag: { name: "和食" } }
    end

    assert_response :unprocessable_content
  end

  # Recipes point at the Tag row rather than the string, which is what makes one
  # rename reach every recipe at once.
  test "update renames the tag everywhere it is used" do
    patch tag_path(@tag), params: { tag: { name: "日本料理" } }

    assert_redirected_to tags_path
    assert_equal "日本料理", @tag.reload.name
    assert_includes recipes(:karaage).reload.tags.map(&:name), "日本料理"
  end

  # Merging the two is a different feature, so the collision is just an error.
  test "update onto a name the user already has re-renders and changes nothing" do
    assert_no_changes -> { @tag.reload.name } do
      patch tag_path(@tag), params: { tag: { name: "豚肉" } }
    end

    assert_response :unprocessable_content
  end

  # The tag leaves every recipe that had it, and the recipes survive.
  test "destroy removes the tag and its join rows but not the recipes" do
    assert_difference [ "Tag.count", "RecipeTag.count" ], -1 do
      assert_no_difference "Recipe.count" do
        delete tag_path(@tag)
      end
    end

    assert_redirected_to tags_path
  end
end
