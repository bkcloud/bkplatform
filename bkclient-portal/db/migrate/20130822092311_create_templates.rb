class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.string :template_id
      t.string :name
      t.string :ostypename
      t.string :details

      t.timestamps
    end
  end
end
