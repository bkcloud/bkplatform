class CreateDatabaseConnections < ActiveRecord::Migration
  def change
    create_table :database_connections do |t|
      t.integer :user_id
      t.string :adapter, :null => false
      t.string :name, :null => false
      t.string :host, :null => false
      t.string :database
      t.string :username
      t.string :password
      t.string :socket

      t.timestamps
    end
  end
end
