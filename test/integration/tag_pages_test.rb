require "test_helper"

class TagPagesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tag = tags(:washoku)

    sign_in_as(@user)
  end

  # The count is the only warning before a delete that cannot be undone.
  test "index shows how many recipes use each tag" do
    get tags_path

    assert_select "#tag_#{@tag.id} .recipes-count",
      text: I18n.t("tags.index.recipes_count", count: 1)
  end

  test "index shows zero for a tag no recipe uses" do
    unused = @user.tags.create!(name: "デザート")

    get tags_path

    assert_select "#tag_#{unused.id} .recipes-count",
      text: I18n.t("tags.index.recipes_count", count: 0)
  end

  test "index names the tag and the count when confirming a delete" do
    get tags_path

    assert_select "#tag_#{@tag.id} form[data-turbo-confirm=?]",
      I18n.t("tags.index.confirm_destroy", name: @tag.name, count: 1)
  end

  test "index says so when there are no tags yet" do
    @user.tags.destroy_all

    get tags_path

    assert_select "p", text: I18n.t("tags.index.empty")
  end

  test "the header links to the tag list" do
    get recipes_path

    assert_select "header a[href=?]", tags_path
  end

  test "new hints the maximum length next to the name field" do
    get new_tag_path

    assert_select "input#tag_name[maxlength=?]", "20"
    assert_select "label[for=tag_name] ~ .max-length-hint", text: I18n.t("shared.forms.max_length_hint", count: 20)
  end
end
