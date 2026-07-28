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
class Ingredient < ApplicationRecord
  belongs_to :recipe

  validates :name, presence: true
  validates :position, presence: true
end
