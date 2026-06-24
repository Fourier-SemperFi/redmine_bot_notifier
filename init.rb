# frozen_string_literal: true

require_relative 'lib/bot_notifier/telegram_sender'
require_relative 'lib/bot_notifier/notifier'
require_relative 'lib/bot_notifier/user_patch'
require_relative 'lib/bot_notifier/issue_patch'
require_relative 'lib/bot_notifier/journal_patch'
require_relative 'lib/bot_notifier/hooks'

Redmine::Plugin.register :bot_notifier do
  name        'Bot Notifier'
  author      'Fourier'
  description 'Sends Telegram notifications to watchers, assignees and authors on issue changes'
  version     '1.1.0'

  settings(
    default: {
      'bot_token'      => '',
      'notify_created' => '1',
      'notify_updated' => '1',
    },
    partial: 'bot_notifier/settings/settings'
  )
end

Rails.application.config.to_prepare do
  User.include(BotNotifier::UserPatch)       unless User.include?(BotNotifier::UserPatch)
  Issue.include(BotNotifier::IssuePatch)     unless Issue.include?(BotNotifier::IssuePatch)
  Journal.include(BotNotifier::JournalPatch) unless Journal.include?(BotNotifier::JournalPatch)
end
