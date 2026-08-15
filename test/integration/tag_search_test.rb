require "test_helper"

class TagSearchTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tag = tags(:washoku)

    sign_in_as(@user)
  end

  test "index lists every tag when nothing is searched" do
    get tags_path

    assert_equal @user.tags.count, listed.count
  end

  test "searching by tag name matches" do
    search "和食"

    assert_equal [ @tag.name ], listed
  end

  # Ransack adds conditions to the relation it is given, so starting from the
  # association is what keeps the search inside the signed-in user's tags.
  test "searching never reaches another user's tags" do
    assert_equal "和食", tags(:two_washoku).name

    search "和食"

    assert_equal [ @tag.name ], listed
  end

  test "index offers a way back out of an active search" do
    search "和食"

    assert_select "#clear-search[href=?]", tags_path
  end

  # "まだタグがありません" would be a lie when the user has plenty and simply
  # searched for something that is not there.
  test "index says nothing matched rather than that there are no tags" do
    search "存在しないタグ"

    assert_select "p", text: I18n.t("tags.index.no_results")
  end

  test "index has nothing to clear when nothing is searched" do
    get tags_path

    assert_select "#clear-search", false
  end

  private
    def search(term)
      get tags_path, params: { q: { Tag::SEARCH_PARAM => term } }
    end

    def listed
      css_select("#tags > li > a").map(&:text)
    end
end
