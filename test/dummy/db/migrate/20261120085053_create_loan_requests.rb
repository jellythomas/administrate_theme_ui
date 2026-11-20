class CreateLoanRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_requests do |t|
      t.references :company, null: false, foreign_key: true
      t.decimal :amount
      t.string :status
      t.date :disbursed_on
      t.text :notes

      t.timestamps
    end
  end
end
