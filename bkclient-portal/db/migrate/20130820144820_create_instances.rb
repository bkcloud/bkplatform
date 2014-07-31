class CreateInstances < ActiveRecord::Migration
  def change
    create_table :instances do |t|
      t.integer :user_id
      t.string :instance_id
      t.string :job_created_id
      t.string :job_id
      t.integer :service_offering_id
      t.integer :disk_offering_id
      t.integer :template_id
      t.string :name,   :null => false,   :default => ""
      t.string :displayname,   :null => false,   :default => ""
      t.string :hostname,   :null => false,   :default => ""
      t.string :port,   :null => false,   :default => ""
      t.string :state, :null => false,   :default => "pending"

      t.timestamps
    end
  end
end
