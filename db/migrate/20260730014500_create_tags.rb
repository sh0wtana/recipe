class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false

      t.timestamps

      t.index [ :user_id, :name ], unique: true
    end
  end
end
