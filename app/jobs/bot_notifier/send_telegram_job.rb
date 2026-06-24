# frozen_string_literal: true

module BotNotifier
  class SendTelegramJob < ApplicationJob
    queue_as :default

    def perform(chat_id, text)
      BotNotifier::TelegramSender.send_message(chat_id, text)
    end
  end
end
