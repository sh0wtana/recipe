require "test_helper"

class RecipePaginationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @limit = RecipesController::PAGE_LIMIT

    sign_in_as(@user)
  end

  test "a full page comes first and the remainder goes to the second" do
    fill_up_to @limit + 1

    get recipes_path
    assert_equal @limit, listed.count

    get recipes_path(page: 2)
    assert_equal 1, listed.count
  end

  # Dropping the search on page two would quietly show unrelated recipes, and
  # nobody notices that while looking for something.
  test "every page link carries an active search" do
    (@limit + 1).times { |i| @user.recipes.create!(title: "カレー#{i}") }

    get recipes_path(q: { Recipe::SEARCH_PARAM => "カレー" })

    links = css_select("nav.pagy a[href]").map { |link| link[:href] }
    assert_predicate links, :any?, "expected the nav to render page links"

    links.each do |href|
      query = Rack::Utils.parse_nested_query(URI.parse(href).query)
      assert_equal "カレー", query.dig("q", Recipe::SEARCH_PARAM.to_s),
        "page link dropped the search: #{href}"
    end
  end

  test "the nav renders even when everything fits on one page" do
    get recipes_path

    assert_select "nav.pagy"
  end

  test "asking for a page past the end renders empty rather than erroring" do
    get recipes_path(page: 999)

    assert_response :success
    assert_empty listed
  end

  # Pagy ships its own i18n and defaults to English, so Rails' default_locale
  # does not reach it.
  test "the nav is labelled in Japanese" do
    fill_up_to @limit + 1

    get recipes_path

    assert_select "nav.pagy a[aria-label=?]", "次へ"
  end

  private
    def fill_up_to(total)
      (total - @user.recipes.count).times { |i| @user.recipes.create!(title: "レシピ#{i}") }
    end

    def listed
      css_select("#recipes > li > a").map(&:text)
    end
end
