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
class Step < ApplicationRecord
  belongs_to :recipe

  validates :body, presence: true
  validates :position, presence: true
end
