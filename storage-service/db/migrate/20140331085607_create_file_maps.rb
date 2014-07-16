class CreateFileMaps < ActiveRecord::Migration
  def change
    create_table :file_maps do |t|
      t.integer :user_id
      t.string :phash
      t.string :remote_url
      t.string :file_name
      t.boolean :is_shared,:default => false

      t.timestamps
    end
  end
end
