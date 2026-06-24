# frozen_string_literal: true

module BotNotifier
  module IssuePatch
    def self.included(base)
      base.after_create_commit :bot_notify_created
    end

    private

    def bot_notify_created
      return unless notify?

      BotNotifier::Notifier.deliver_issue_created(self)
    rescue => e
      Rails.logger.error "[BotNotifier] issue created notify error: #{e.message}"
    end
  end
end
