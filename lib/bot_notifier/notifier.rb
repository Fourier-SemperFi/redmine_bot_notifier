# frozen_string_literal: true

module BotNotifier
  module Notifier
    SUPPORTED_LOCALES = %w[en uk de pl ru].freeze

    def self.deliver_issue_created(issue)
      s = Setting.plugin_bot_notifier
      return unless s[:bot_token].to_s.strip.present?
      return unless s[:notify_created] == '1'

      recipients = collect_recipients_for_issue(issue)
      return if recipients.empty?

      recipients.each do |r|
        text = I18n.with_locale(r[:locale]) { build_issue_created_message(issue) }
        BotNotifier::SendTelegramJob.perform_later(r[:chat_id], text)
      end
    end

    def self.deliver_issue_updated(journal)
      s = Setting.plugin_bot_notifier
      return unless s[:bot_token].to_s.strip.present?
      return unless s[:notify_updated] == '1'

      issue = journal.journalized
      return unless issue.is_a?(Issue)

      recipients = collect_recipients_for_issue(issue)
      return if recipients.empty?

      recipients.each do |r|
        text = I18n.with_locale(r[:locale]) { build_issue_updated_message(journal, issue) }
        BotNotifier::SendTelegramJob.perform_later(r[:chat_id], text)
      end
    end

    def self.collect_recipients_for_issue(issue)
      users = []
      users += issue.notified_watchers
      users += [issue.assigned_to].compact
      users += [issue.author].compact

      users = users.flat_map { |u| u.is_a?(Group) ? u.users.active.to_a : u }
      users.uniq!
      users.select!(&:active?)

      users.filter_map do |user|
        chat = UserTelegramChat.find_by(user_id: user.id)
        next unless chat
        locale = supported_locale(user.language.presence || Setting.default_language)
        { chat_id: chat.chat_id, locale: locale }
      end.uniq { |r| r[:chat_id] }
    end

    def self.supported_locale(lang)
      SUPPORTED_LOCALES.include?(lang.to_s) ? lang.to_s : 'en'
    end

    def self.build_issue_created_message(issue)
      url = issue_url(issue)
      t  = ->(key, **opts) { I18n.t("bot_notifier.#{key}", **opts) }

      lines = []
      lines << t.call(:msg_new_issue, tracker: issue.tracker, id: issue.id)
      lines << "📌 #{escape(issue.subject)}"
      lines << ""
      lines << "#{t.call(:msg_assignee)}: #{escape(issue.assigned_to&.name || '—')}"
      lines << "#{t.call(:msg_priority)}: #{escape(issue.priority&.name || '—')}"
      lines << "#{t.call(:msg_status)}: #{escape(issue.status&.name || '—')}"
      lines << "#{t.call(:msg_project)}: #{escape(issue.project&.name || '—')}"

      watchers = watcher_names(issue)
      lines << "#{t.call(:msg_watchers)}: #{watchers}" if watchers.present?

      lines << ""
      lines << "<a href=\"#{url}\">#{t.call(:msg_open_issue, id: issue.id)}</a>"
      lines.join("\n")
    end

    def self.build_issue_updated_message(journal, issue)
      url = issue_url(issue)
      t  = ->(key, **opts) { I18n.t("bot_notifier.#{key}", **opts) }

      lines = []
      lines << t.call(:msg_updated_issue, tracker: issue.tracker, id: issue.id)
      lines << "📌 #{escape(issue.subject)}"
      lines << ""

      changes = format_changes(journal)
      if changes.any?
        lines << t.call(:msg_changes)
        lines += changes
        lines << ""
      end

      if journal.notes.present?
        lines << t.call(:msg_comment)
        lines << escape(journal.notes.truncate(300))
        lines << ""
      end

      lines << "#{t.call(:msg_changed_by)}: #{escape(journal.user&.name || '—')}"
      lines << "<a href=\"#{url}#change-#{journal.id}\">#{t.call(:msg_open_issue, id: issue.id)}</a>"
      lines.join("\n")
    end

    def self.format_changes(journal)
      t = ->(key, **opts) { I18n.t("bot_notifier.#{key}", **opts) }

      journal.details.filter_map do |detail|
        label = label_for_detail(detail)
        next if label.nil?

        old_val = value_label_for_detail(detail, detail.old_value)
        new_val = value_label_for_detail(detail, detail.value)

        if detail.property == 'attachment'
          if detail.value.present?
            t.call(:msg_file_added, name: escape(new_val))
          else
            t.call(:msg_file_removed, name: escape(old_val))
          end
        elsif old_val.present? && new_val.present?
          t.call(:msg_field_changed, field: label, old: escape(old_val), new: escape(new_val))
        elsif new_val.present?
          t.call(:msg_field_set, field: label, new: escape(new_val))
        elsif old_val.present?
          t.call(:msg_field_cleared, field: label, old: escape(old_val))
        end
      end
    end

    def self.label_for_detail(detail)
      case detail.property
      when 'attr'
        I18n.t("bot_notifier.field_#{detail.prop_key}", default: nil)
      when 'cf'
        CustomField.find_by(id: detail.prop_key)&.name
      when 'attachment'
        I18n.t('bot_notifier.field_attachment')
      when 'relation'
        I18n.t('bot_notifier.field_relation')
      end
    end

    def self.value_label_for_detail(detail, raw)
      return '' if raw.blank?

      case detail.prop_key
      when 'status_id'       then IssueStatus.find_by(id: raw)&.name || raw
      when 'assigned_to_id'  then Principal.find_by(id: raw)&.name || raw
      when 'priority_id'     then IssuePriority.find_by(id: raw)&.name || raw
      when 'fixed_version_id' then Version.find_by(id: raw)&.name || raw
      when 'category_id'     then IssueCategory.find_by(id: raw)&.name || raw
      when 'tracker_id'      then Tracker.find_by(id: raw)&.name || raw
      when 'project_id'      then Project.find_by(id: raw)&.name || raw
      else raw.to_s
      end
    end

    def self.watcher_names(issue)
      issue.notified_watchers
           .flat_map { |u| u.is_a?(Group) ? u.users.active.to_a : u }
           .uniq
           .map { |u| escape(u.name) }
           .join(', ')
    end

    def self.issue_url(issue)
      "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue.id}"
    end

    def self.escape(str)
      str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end
  end
end
