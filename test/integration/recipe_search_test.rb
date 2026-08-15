require "test_helper"

class RecipeSearchTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @recipe = recipes(:karaage)

    # A second recipe of the user's own, so a search that matches everything
    # cannot pass for one that matched the right thing.
    @user.recipes.create!(title: "肉じゃが")

    sign_in_as(@user)
  end

  test "index lists every recipe when nothing is searched" do
    get recipes_path

    assert_equal @user.recipes.count, listed.count
  end

  test "searching by recipe title matches" do
    search "からあげ"

    assert_equal [ @recipe.title ], listed
  end

  test "searching by ingredient name matches" do
    search "醤油"

    assert_equal [ @recipe.title ], listed
  end

  test "searching by tag name matches" do
    search "和食"

    assert_equal [ @recipe.title ], listed
  end

  # Unlisted columns are unreachable through search, so the failure mode is
  # closed rather than open. This one is prose and would only add noise.
  test "a term that appears only in the description does not match" do
    assert_includes @recipe.description, "家族"

    search "家族"

    assert_empty listed
  end

  # Ransack adds conditions to the relation it is given, so starting from the
  # association is what keeps the search inside the signed-in user's recipes.
  test "searching never reaches another user's recipes" do
    assert_equal "味噌汁", recipes(:miso_soup).title

    search "味噌"

    assert_empty listed
  end

  # Matching across a has_many join returns the recipe once per matching row.
  test "a recipe matching in more than one place is listed once" do
    @recipe.tags << @user.tags.create!(name: "からあげ")

    search "からあげ"

    assert_equal [ @recipe.title ], listed
  end

  test "index links each tag to a search for it" do
    get recipes_path

    assert_select "a[href=?]", recipes_path(q: { Recipe::SEARCH_PARAM => "和食" }), text: "和食"
  end

  test "index offers a way back out of an active search" do
    search "和食"

    assert_select "#clear-search[href=?]", recipes_path
  end

  # "まだレシピがありません" would be a lie when the user has plenty and simply
  # searched for something that is not there.
  test "index says nothing matched rather than that there are no recipes" do
    search "存在しない料理"

    assert_select "p", text: I18n.t("recipes.index.no_results")
  end

  test "index has nothing to clear when nothing is searched" do
    get recipes_path

    assert_select "#clear-search", false
  end

  private
    def search(term)
      get recipes_path, params: { q: { Recipe::SEARCH_PARAM => term } }
    end

    # Direct children only, because each row carries a nested list of tag links.
    def listed
      css_select("#recipes > li > a").map(&:text)
    end
end
