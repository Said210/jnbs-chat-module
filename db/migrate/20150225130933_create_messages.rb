class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :sent_by
      t.integer :sent_to
      t.integer :status, :default => 0 #0 = SEEN, 1 = NOT SEEN YET
      t.text :message


      t.timestamps
    end
  end
end
