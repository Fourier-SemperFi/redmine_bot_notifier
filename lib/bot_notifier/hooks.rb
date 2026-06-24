# frozen_string_literal: true

module BotNotifier
  class Hooks < Redmine::Hook::ViewListener
    def view_users_form(context = {})
      user = context[:user]
      return '' unless user&.id

      chat        = UserTelegramChat.find_by(user_id: user.id)
      value       = ERB::Util.html_escape(chat&.chat_id.to_s)
      label       = ERB::Util.html_escape(I18n.t('bot_notifier.label_chat_id'))
      placeholder = ERB::Util.html_escape(I18n.t('bot_notifier.placeholder_chat_id'))
      hint        = ERB::Util.html_escape(I18n.t('bot_notifier.hint_chat_id'))

      <<~HTML
        <p>
          <label for="user_telegram_chat_id">#{label}</label>
          <input type="text"
                 id="user_telegram_chat_id"
                 name="user[telegram_chat_id]"
                 value="#{value}"
                 placeholder="#{placeholder}"
                 size="25" />
          <em class="info">#{hint}</em>
        </p>
      HTML
    end

    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      return unless issue

      BotNotifier::Notifier.deliver_issue_created(issue)
    rescue => e
      Rails.logger.error "[BotNotifier] controller_issues_new_after_save error: #{e.message}"
    end

    def controller_issues_edit_after_save(context = {})
      journal = context[:journal]
      return unless journal

      BotNotifier::Notifier.deliver_issue_updated(journal)
    rescue => e
      Rails.logger.error "[BotNotifier] controller_issues_edit_after_save error: #{e.message}"
    end
  end
end
