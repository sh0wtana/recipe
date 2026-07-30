class CreateRecipeTags < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_tags do |t|
      t.references :recipe, null: false, foreign_key: true, index: false
      t.references :tag, null: false, foreign_key: true

      t.timestamps

      t.index [ :recipe_id, :tag_id ], unique: true
    end
  end
end
