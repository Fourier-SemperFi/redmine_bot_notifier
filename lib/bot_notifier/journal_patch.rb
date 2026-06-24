# frozen_string_literal: true

module BotNotifier
  module JournalPatch
    def self.included(base)
      base.after_create_commit :bot_notify_updated
    end

    private

    def bot_notify_updated
      return unless notify?
      return unless journalized.is_a?(Issue)

      BotNotifier::Notifier.deliver_issue_updated(self)
    rescue => e
      Rails.logger.error "[BotNotifier] journal notify error: #{e.message}"
    end
  end
end
