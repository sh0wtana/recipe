require "test_helper"

# == Schema Information
#
# Table name: ingredients
#
#  id         :integer          not null, primary key
#  amount     :string
#  name       :string           not null
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#
# Indexes
#
#  index_ingredients_on_recipe_id  (recipe_id)
#
# Foreign Keys
#
#  recipe_id  (recipe_id => recipes.id)
#
class IngredientTest < ActiveSupport::TestCase
  test "is valid with a name, a position and a recipe" do
    assert_predicate Ingredient.new(recipe: recipes(:karaage), name: "塩", position: 0), :valid?
  end

  test "requires a name" do
    ingredient = Ingredient.new(recipe: recipes(:karaage), name: "", position: 0)

    assert_predicate ingredient, :invalid?
    assert ingredient.errors.of_kind?(:name, :blank)
  end

  test "requires a position" do
    ingredient = Ingredient.new(recipe: recipes(:karaage), name: "塩")

    assert_predicate ingredient, :invalid?
    assert ingredient.errors.of_kind?(:position, :blank)
  end

  test "accepts position zero" do
    assert_predicate Ingredient.new(recipe: recipes(:karaage), name: "塩", position: 0), :valid?
  end

  test "requires a recipe" do
    ingredient = Ingredient.new(name: "塩", position: 0)

    assert_predicate ingredient, :invalid?
    assert_predicate ingredient.errors[:recipe], :any?
  end

  test "amount is optional and free text" do
    assert_predicate ingredients(:karaage_ginger).amount, :nil?

    ingredient = Ingredient.new(recipe: recipes(:karaage), name: "塩", amount: "少々", position: 0)

    assert_predicate ingredient, :valid?
  end
end
