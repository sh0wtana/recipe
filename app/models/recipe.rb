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
class Recipe < ApplicationRecord
  belongs_to :user

  has_many :ingredients, -> { order(:position) }, dependent: :destroy
  has_many :steps,       -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :steps,       allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
end
