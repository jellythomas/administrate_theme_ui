class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :status
      t.decimal :credit_limit
      t.boolean :active

      t.timestamps
    end
  end
end
