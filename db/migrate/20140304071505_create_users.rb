class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :loginname,       null: false, default: ""
      t.string :password_bcrypt, null: false, default: ""
      t.timestamps
    end
  end
end
