class CreateDiskOfferings < ActiveRecord::Migration
  def change
    create_table :disk_offerings do |t|
      t.string :disk_offering_id
      t.string :disksize
      t.string :storagetype

      t.timestamps
    end
  end
end
