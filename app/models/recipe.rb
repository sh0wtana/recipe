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

  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags

  # :all_blank, except that position does not count. JavaScript writes it on
  # every row, so an untouched row would read as filled in and then fail its
  # presence validation. _destroy needs no handling: call_reject_if skips the
  # predicate entirely for a row already marked for destruction.
  BLANK_ROW = ->(attrs) { attrs.all? { |key, value| key.in?(%w[position _destroy]) || value.blank? } }

  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: BLANK_ROW
  accepts_nested_attributes_for :steps,       allow_destroy: true, reject_if: BLANK_ROW

  validates :title, presence: true

  # Join rows need the recipe's id, so they wait until after the insert.
  # nil means the form sent no tags; [] means the user cleared them all.
  after_save :apply_tag_names, if: -> { @tag_names }

  # Normalize before uniq so ｶﾚｰ and カレー collapse into one name.
  def tag_names=(names)
    @tag_names = Array(names)
      .map { |name| name.unicode_normalize(:nfkc).strip }
      .reject(&:blank?)
      .uniq
  end

  # Prefer what was submitted, so a form re-rendered after a failed
  # validation still shows what the user typed.
  def tag_names
    @tag_names || tags.map(&:name)
  end

  private
    # Scoped to the recipe's own user so tags never cross accounts.
    # Assignment replaces the join rows; the Tag itself is left alone.
    def apply_tag_names
      self.tags = @tag_names.map { |name| user.tags.find_or_create_by(name: name) }
    end
end
