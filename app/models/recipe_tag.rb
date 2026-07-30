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
class RecipeTag < ApplicationRecord
  belongs_to :recipe
  belongs_to :tag
end
