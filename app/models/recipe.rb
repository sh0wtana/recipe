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

  # format: :jpeg on both. Rails defaults a non-web-image variant to PNG, so a
  # HEIC photo would silently become a multi-megabyte PNG that still displays.
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 192, 192 ], format: :jpeg
    attachable.variant :large, resize_to_limit: [ 1200, 1200 ], format: :jpeg
  end

  # An empty file field means "leave the photo alone", so deleting needs its own
  # signal. The form's 🗑 button sets this.
  attr_accessor :remove_photo

  # Rails' :all_blank plus position, which JavaScript writes on every row —
  # without it, a row the user never touched looks filled in and blocks the save.
  BLANK_ROW = ->(attrs) { attrs.all? { |key, value| key.in?(%w[position _destroy]) || value.blank? } }

  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: BLANK_ROW
  accepts_nested_attributes_for :steps,       allow_destroy: true, reject_if: BLANK_ROW

  validates :title, presence: true, length: { maximum: 20 }
  validates :description, length: { maximum: 320 }
  validates :servings, length: { maximum: 25 }
  validates :tips, length: { maximum: 120 }

  # MIME strings rather than the gem's symbol shorthand. The symbols resolve
  # through Marcel's extension table, and HEIC's entry there is not worth
  # depending on.
  validates :photo, content_type: %w[ image/jpeg image/png image/webp image/heic image/heif ],
                    size: { less_than: 10.megabytes }

  # A column left out here is unreachable through search, not just unlisted.
  def self.ransackable_attributes(_auth_object = nil) = %w[title]
  def self.ransackable_associations(_auth_object = nil) = %w[tags ingredients]

  # ransack_alias would shorten this in the URL, but in 4.4.1 the aliased
  # condition is dropped without a word and every recipe comes back.
  SEARCH_PARAM = :title_or_ingredients_name_or_tags_name_cont

  # Join rows need the recipe's id, so they wait until after the insert.
  # nil means the form sent no tags; [] means the user cleared them all.
  after_save :apply_tag_names, if: -> { @tag_names }

  # Read before the save, because Active Storage clears attachment_changes once
  # it has uploaded them.
  before_save :note_photo_replacement
  after_save :purge_photo, if: -> { remove_photo == "1" && !@photo_replaced }

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

    def note_photo_replacement
      @photo_replaced = attachment_changes.key?("photo")
    end

    # purge, not purge_later: bin/dev runs no job worker, so an enqueued purge
    # would sit in the queue and never delete the file locally.
    def purge_photo
      photo.purge
    end
end
