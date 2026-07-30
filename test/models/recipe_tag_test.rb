require "test_helper"

# == Schema Information
#
# Table name: recipe_tags
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#  tag_id     :integer          not null
#
# Indexes
#
#  index_recipe_tags_on_recipe_id_and_tag_id  (recipe_id,tag_id) UNIQUE
#  index_recipe_tags_on_tag_id                (tag_id)
#
# Foreign Keys
#
#  recipe_id  (recipe_id => recipes.id)
#  tag_id     (tag_id => tags.id)
#
class RecipeTagTest < ActiveSupport::TestCase
  test "is valid with a recipe and a tag" do
    assert_predicate RecipeTag.new(recipe: recipes(:miso_soup), tag: tags(:two_washoku)), :valid?
  end

  test "requires a recipe" do
    join = RecipeTag.new(tag: tags(:washoku))

    assert_predicate join, :invalid?
    assert_predicate join.errors[:recipe], :any?
  end

  test "requires a tag" do
    join = RecipeTag.new(recipe: recipes(:karaage))

    assert_predicate join, :invalid?
    assert_predicate join.errors[:tag], :any?
  end

  test "the database rejects the same tag twice on one recipe" do
    assert_raises ActiveRecord::RecordNotUnique do
      RecipeTag.insert!({ recipe_id: recipes(:karaage).id, tag_id: tags(:washoku).id })
    end
  end
end
