require "test_helper"

# == Schema Information
#
# Table name: recipes
#
#  id          :integer          not null, primary key
#  description :text
#  servings    :string
#  tips        :text
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_recipes_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class RecipeTest < ActiveSupport::TestCase
  test "is valid with a title and a user" do
    assert_predicate Recipe.new(user: users(:one), title: "肉じゃが"), :valid?
  end

  test "requires a title" do
    recipe = Recipe.new(user: users(:one), title: "")

    assert_predicate recipe, :invalid?
    assert recipe.errors.of_kind?(:title, :blank)
  end

  test "requires a user" do
    recipe = Recipe.new(title: "肉じゃが")

    assert_predicate recipe, :invalid?
    assert_predicate recipe.errors[:user], :any?
  end

  test "description, servings and tips are optional" do
    recipe = Recipe.new(user: users(:one), title: "肉じゃが",
                        description: "", servings: "", tips: "")

    assert_predicate recipe, :valid?
  end

  test "rejects a title over 20 characters" do
    recipe = Recipe.new(user: users(:one), title: "あ" * 21)

    assert_predicate recipe, :invalid?
    assert recipe.errors.of_kind?(:title, :too_long)
  end

  test "accepts a title of exactly 20 characters" do
    assert_predicate Recipe.new(user: users(:one), title: "あ" * 20), :valid?
  end

  test "rejects a description over 320 characters" do
    recipe = Recipe.new(user: users(:one), title: "肉じゃが", description: "あ" * 321)

    assert_predicate recipe, :invalid?
    assert recipe.errors.of_kind?(:description, :too_long)
  end

  test "accepts a description of exactly 320 characters" do
    assert_predicate Recipe.new(user: users(:one), title: "肉じゃが", description: "あ" * 320), :valid?
  end

  test "rejects servings over 25 characters" do
    recipe = Recipe.new(user: users(:one), title: "肉じゃが", servings: "あ" * 26)

    assert_predicate recipe, :invalid?
    assert recipe.errors.of_kind?(:servings, :too_long)
  end

  test "accepts servings of exactly 25 characters" do
    assert_predicate Recipe.new(user: users(:one), title: "肉じゃが", servings: "あ" * 25), :valid?
  end

  test "rejects tips over 120 characters" do
    recipe = Recipe.new(user: users(:one), title: "肉じゃが", tips: "あ" * 121)

    assert_predicate recipe, :invalid?
    assert recipe.errors.of_kind?(:tips, :too_long)
  end

  test "accepts tips of exactly 120 characters" do
    assert_predicate Recipe.new(user: users(:one), title: "肉じゃが", tips: "あ" * 120), :valid?
  end

  test "ingredients are ordered by position, not by id" do
    recipe = recipes(:karaage)
    recipe.ingredients.destroy_all

    recipe.ingredients.create!(name: "みりん", position: 2)
    recipe.ingredients.create!(name: "酒",     position: 0)
    recipe.ingredients.create!(name: "砂糖",   position: 1)

    assert_equal %w[酒 砂糖 みりん], recipe.reload.ingredients.map(&:name)
  end

  test "steps are ordered by position, not by id" do
    recipe = recipes(:karaage)
    recipe.steps.destroy_all

    recipe.steps.create!(body: "盛り付ける", position: 2)
    recipe.steps.create!(body: "材料を切る", position: 0)
    recipe.steps.create!(body: "炒める",     position: 1)

    assert_equal [ "材料を切る", "炒める", "盛り付ける" ], recipe.reload.steps.map(&:body)
  end

  test "destroying a recipe destroys its ingredients" do
    assert_difference "Ingredient.count", -3 do
      recipes(:karaage).destroy
    end
  end

  test "destroying a recipe destroys its steps" do
    assert_difference "Step.count", -2 do
      recipes(:karaage).destroy
    end
  end

  test "accepts nested ingredients" do
    recipe = Recipe.new(user: users(:one), title: "肉じゃが",
                        ingredients_attributes: [ { name: "じゃがいも", amount: "3個", position: 0 } ])

    assert_difference "Ingredient.count", 1 do
      recipe.save!
    end
  end

  test "accepts nested steps" do
    recipe = Recipe.new(user: users(:one), title: "肉じゃが",
                        steps_attributes: [ { body: "材料を切る", position: 0 } ])

    assert_difference "Step.count", 1 do
      recipe.save!
    end
  end

  test "rejects an all-blank ingredient row instead of failing validation" do
    recipe = recipes(:karaage)

    assert_no_difference "Ingredient.count" do
      recipe.update!(ingredients_attributes: [ { name: "", amount: "", position: "" } ])
    end
  end

  test "rejects an all-blank step row instead of failing validation" do
    recipe = recipes(:karaage)

    assert_no_difference "Step.count" do
      recipe.update!(steps_attributes: [ { body: "", position: "" } ])
    end
  end

  # renumber() writes position on every row, so a row the user never typed in
  # still arrives with one.
  test "rejects a blank ingredient row that carries a position" do
    recipe = recipes(:karaage)

    assert_no_difference "Ingredient.count" do
      recipe.update!(ingredients_attributes: [ { name: "", amount: "", position: "3" } ])
    end
  end

  test "rejects a blank step row that carries a position" do
    recipe = recipes(:karaage)

    assert_no_difference "Step.count" do
      recipe.update!(steps_attributes: [ { body: "", position: "2" } ])
    end
  end

  test "a partially filled ingredient row is still validated" do
    recipe = recipes(:karaage)

    assert_raises ActiveRecord::RecordInvalid do
      recipe.update!(ingredients_attributes: [ { name: "", amount: "少々", position: 9 } ])
    end
  end

  test "destroys a nested ingredient marked _destroy" do
    recipe = recipes(:karaage)
    ingredient = recipe.ingredients.first

    assert_difference "Ingredient.count", -1 do
      recipe.update!(ingredients_attributes: [ { id: ingredient.id, _destroy: "1" } ])
    end
  end

  test "destroys a nested step marked _destroy" do
    recipe = recipes(:karaage)
    step = recipe.steps.first

    assert_difference "Step.count", -1 do
      recipe.update!(steps_attributes: [ { id: step.id, _destroy: "1" } ])
    end
  end

  test "has its tags through recipe_tags" do
    assert_equal %w[和食 豚肉].sort, recipes(:karaage).tags.map(&:name).sort
  end

  test "destroying a recipe destroys its join rows but not the tags" do
    assert_difference "RecipeTag.count", -2 do
      assert_no_difference "Tag.count" do
        recipes(:karaage).destroy
      end
    end
  end

  test "tag_names defaults to the persisted tag names" do
    assert_equal %w[和食 豚肉].sort, recipes(:karaage).tag_names.sort
  end

  test "applying tag names creates tags owned by the recipe's user" do
    recipe = recipes(:miso_soup)

    assert_difference "Tag.count", 1 do
      recipe.update!(tag_names: [ "洋食" ])
    end

    assert_equal users(:two), recipe.tags.sole.user
  end

  test "applying another user's tag name creates the owner's own tag" do
    recipe = recipes(:miso_soup)

    assert_difference "Tag.count", 1 do
      recipe.update!(tag_names: [ "豚肉" ])
    end

    tag = recipe.tags.sole

    assert_equal users(:two), tag.user
    refute_equal tags(:pork), tag
  end

  test "applying the same name twice reuses the existing tag" do
    recipe = recipes(:miso_soup)
    recipe.update!(tag_names: [ "洋食" ])

    assert_no_difference "Tag.count" do
      recipe.update!(tag_names: [ "洋食" ])
    end
  end

  test "half-width and full-width forms of a name resolve to one tag" do
    recipe = recipes(:miso_soup)

    assert_difference "Tag.count", 1 do
      recipe.update!(tag_names: [ "ｶﾚｰ" ])
      recipe.update!(tag_names: [ "カレー" ])
    end

    assert_equal [ "カレー" ], recipe.reload.tags.map(&:name)
  end

  test "replacing tag names removes the join row but keeps the tag" do
    recipe = recipes(:karaage)

    assert_difference "RecipeTag.count", -1 do
      assert_no_difference "Tag.count" do
        recipe.update!(tag_names: [ "和食" ])
      end
    end

    assert_equal [ "和食" ], recipe.reload.tags.map(&:name)
    assert Tag.exists?(tags(:pork).id)
  end

  test "an empty tag_names array clears every tag" do
    recipe = recipes(:karaage)

    assert_difference "RecipeTag.count", -2 do
      recipe.update!(tag_names: [])
    end

    assert_empty recipe.reload.tags
  end

  test "an update that does not mention tag_names leaves the tags alone" do
    recipe = recipes(:karaage)

    assert_no_difference "RecipeTag.count" do
      recipe.update!(title: "からあげ（改）")
    end
  end

  test "blank names are ignored and duplicates collapse" do
    recipe = recipes(:miso_soup)

    assert_difference "Tag.count", 1 do
      recipe.update!(tag_names: [ "", "  ", "洋食", "洋食" ])
    end

    assert_equal [ "洋食" ], recipe.reload.tags.map(&:name)
  end

  test "tag_names reads back what was submitted when validation fails" do
    recipe = recipes(:karaage)
    recipe.attributes = { title: "", tag_names: [ "洋食" ] }

    assert_predicate recipe, :invalid?
    assert_equal [ "洋食" ], recipe.tag_names
  end
end
