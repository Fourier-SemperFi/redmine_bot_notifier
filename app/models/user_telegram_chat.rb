# frozen_string_literal: true

class UserTelegramChat < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :chat_id, presence: true,
    format: {
      with:    /\A-?\d+\z/,
      message: ->(_obj, _data) { I18n.t('bot_notifier.error_invalid_chat_id') }
    }
end
