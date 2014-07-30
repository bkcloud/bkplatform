class CreateServiceOfferings < ActiveRecord::Migration
  def change
    create_table :service_offerings do |t|
      t.string :service_offering_id
      t.integer :cpunumber
      t.integer :cpuspeed
      t.integer :memory
      t.boolean :offerha

      t.timestamps
    end
  end
end
