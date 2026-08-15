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

  validates :name, presence: true, length: { maximum: 30 }
  validates :amount, length: { maximum: 30 }
  validates :position, presence: true

  # Reached only through a Recipe search, so no association needs opening up.
  def self.ransackable_attributes(_auth_object = nil) = %w[name]
  def self.ransackable_associations(_auth_object = nil) = []
end
