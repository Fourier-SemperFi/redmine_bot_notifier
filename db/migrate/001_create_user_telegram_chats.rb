class CreateUserTelegramChats < ActiveRecord::Migration[7.0]
  def up
    create_table :user_telegram_chats do |t|
      t.integer :user_id, null: false
      t.string  :chat_id, null: false
      t.timestamps
    end
    add_index :user_telegram_chats, :user_id, unique: true
  end

  def down
    drop_table :user_telegram_chats
  end
end
