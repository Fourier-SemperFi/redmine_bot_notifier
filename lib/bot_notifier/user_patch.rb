# frozen_string_literal: true

module BotNotifier
  module UserPatch
    def self.included(base)
      base.safe_attributes 'telegram_chat_id'
      base.after_save :persist_telegram_chat_id
    end

    def telegram_chat_id
      @telegram_chat_id ||= UserTelegramChat.find_by(user_id: id)&.chat_id.to_s
    end

    def telegram_chat_id=(val)
      @telegram_chat_id = val.to_s.strip
      @telegram_chat_id_changed = true
    end

    private

    def persist_telegram_chat_id
      return unless @telegram_chat_id_changed

      record = UserTelegramChat.find_or_initialize_by(user_id: id)
      if @telegram_chat_id.blank?
        record.destroy if record.persisted?
      else
        record.chat_id = @telegram_chat_id
        record.save
      end
      @telegram_chat_id_changed = false
    end
  end
end
