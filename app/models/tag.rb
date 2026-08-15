# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_tags_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Tag < ApplicationRecord
  belongs_to :user

  has_many :recipe_tags, dependent: :destroy
  has_many :recipes, through: :recipe_tags

  normalizes :name, with: ->(n) { n.unicode_normalize(:nfkc).strip }

  validates :name, presence: true, uniqueness: { scope: :user_id }

  # Reached only through a Recipe search, so no association needs opening up.
  def self.ransackable_attributes(_auth_object = nil) = %w[name]
  def self.ransackable_associations(_auth_object = nil) = []
end
