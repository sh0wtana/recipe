require "test_helper"

# == Schema Information
#
# Table name: steps
#
#  id         :integer          not null, primary key
#  body       :text             not null
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#
# Indexes
#
#  index_steps_on_recipe_id  (recipe_id)
#
# Foreign Keys
#
#  recipe_id  (recipe_id => recipes.id)
#
class StepTest < ActiveSupport::TestCase
  test "is valid with a body, a position and a recipe" do
    assert_predicate Step.new(recipe: recipes(:karaage), body: "材料を切る", position: 0), :valid?
  end

  test "requires a body" do
    step = Step.new(recipe: recipes(:karaage), body: "", position: 0)

    assert_predicate step, :invalid?
    assert step.errors.of_kind?(:body, :blank)
  end

  test "requires a position" do
    step = Step.new(recipe: recipes(:karaage), body: "材料を切る")

    assert_predicate step, :invalid?
    assert step.errors.of_kind?(:position, :blank)
  end

  test "accepts position zero" do
    assert_predicate Step.new(recipe: recipes(:karaage), body: "材料を切る", position: 0), :valid?
  end

  test "requires a recipe" do
    step = Step.new(body: "材料を切る", position: 0)

    assert_predicate step, :invalid?
    assert_predicate step.errors[:recipe], :any?
  end
end
