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
end
