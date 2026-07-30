require "test_helper"

# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_tags_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class TagTest < ActiveSupport::TestCase
  test "is valid with a user and a name" do
    assert_predicate Tag.new(user: users(:one), name: "デザート"), :valid?
  end

  test "requires a name" do
    tag = Tag.new(user: users(:one), name: "")

    assert_predicate tag, :invalid?
    assert tag.errors.of_kind?(:name, :blank)
  end

  test "requires a user" do
    tag = Tag.new(name: "デザート")

    assert_predicate tag, :invalid?
    assert_predicate tag.errors[:user], :any?
  end

  test "requires a name unique per user" do
    tag = Tag.new(user: users(:one), name: "和食")

    assert_predicate tag, :invalid?
    assert tag.errors.of_kind?(:name, :taken)
  end

  test "the same name may be used by another user" do
    assert_predicate Tag.new(user: users(:two), name: "豚肉"), :valid?
  end

  test "the database rejects a duplicate name for the same user" do
    assert_raises ActiveRecord::RecordNotUnique do
      Tag.insert!({ user_id: users(:one).id, name: "和食" })
    end
  end

  test "strips whitespace from the name" do
    assert_equal "デザート", Tag.new(name: "  デザート  ").name
  end

  test "normalizes half-width katakana and full-width alphanumerics" do
    assert_equal "カレー", Tag.new(name: "ｶﾚｰ").name
    assert_equal "Pasta", Tag.new(name: "Ｐａｓｔａ").name
  end

  test "does not fold hiragana into katakana" do
    assert_equal "かれー", Tag.new(name: "かれー").name
  end

  test "normalization applies to finders too" do
    tag = users(:one).tags.create!(name: "カレー")

    assert_equal tag, users(:one).tags.find_by(name: "ｶﾚｰ")
  end

  test "has its recipes through recipe_tags" do
    assert_equal [ recipes(:karaage) ], tags(:washoku).recipes.to_a
  end

  test "destroying a tag destroys its join rows but not its recipes" do
    assert_difference "RecipeTag.count", -1 do
      assert_no_difference "Recipe.count" do
        tags(:washoku).destroy
      end
    end
  end

  test "destroying a user destroys their tags" do
    assert_difference "Tag.count", -2 do
      users(:one).destroy
    end
  end
end
