# Bot Notifier — Redmine Telegram Plugin

Redmine plugin that sends Telegram notifications to issue watchers, assignees, and authors when issues are created or updated.

---

## Features

- Notifications on issue **create** and **update**
- Recipients: **watchers**, **assignee**, **author** (groups are expanded to individual users)
- Per-recipient **language** — each user gets the message in their own Redmine language
- Supported languages: 🇺🇦 Ukrainian · 🇬🇧 English · 🇩🇪 German · 🇵🇱 Polish · 🇷🇺 Russian
- Message includes: subject, assignee, priority, status, project, watchers list, field changes, comments, direct link
- **Admin-only** Chat ID management via web UI — no bot webhooks, no self-registration
- Async delivery via ActiveJob (non-blocking)
- Seamless — disabling the plugin removes all functionality with zero core changes

---

## Requirements

| Component | Version     |
|-----------|-------------|
| Redmine   | >= 5.0      |
| Ruby      | >= 3.0      |
| Rails     | >= 7.0      |

Tested on **Redmine 6.0.5**, Ruby 3.1.4, Rails 7.2.2.

---

## Installation

**1. Copy the plugin**

```bash
cp -r bot_notifier /path/to/redmine/plugins/
```

**2. Run the migration**

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

**3. Restart Redmine**

```bash
systemctl restart redmine.service
# or
touch tmp/restart.txt
```

---

## Configuration

### Bot token

1. Open **Administration → Plugins → Bot Notifier → Configure**
2. Paste your bot token from [@BotFather](https://t.me/BotFather)
3. Enable/disable notifications for new issues and updates
4. Save

### User Chat ID

1. Open **Administration → Users → [select user] → Edit**
2. Fill in the **Telegram Chat ID** field with the user's numeric chat ID
3. Save

> **How to get Chat ID:** the user sends any message to the bot, then you (admin) check it via  
> `https://api.telegram.org/bot<TOKEN>/getUpdates` — look for `message.chat.id`.

If Chat ID is empty for a user — they simply won't receive notifications.

---

## Notification examples

**New issue**
```
🆕 New issue: Bug #2409
📌 Login page broken

👤 Assignee: John Doe
🔴 Priority: High
📊 Status: New
🗂 Project: Website
👁 Watchers: Jane Smith, Bob Lee

🔗 Open issue #2409
```

**Issue updated**
```
✏️ Update: Bug #2409
📌 Login page broken

📋 Changes:
• Status: New → In Progress
• Assignee: John Doe → Jane Smith

💬 Comment:
Started investigating the root cause.

👤 Changed by: Jane Smith
🔗 Open issue #2409
```

---

## Uninstall

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate NAME=bot_notifier VERSION=0 RAILS_ENV=production
rm -rf plugins/bot_notifier
systemctl restart redmine.service
```

---

## File structure

```
bot_notifier/
├── app/
│   ├── jobs/bot_notifier/send_telegram_job.rb   # ActiveJob async delivery
│   ├── models/user_telegram_chat.rb             # chat_id ↔ user mapping
│   └── views/bot_notifier/settings/
│       └── _settings.html.erb                   # Admin settings form
├── config/
│   └── locales/
│       ├── en.yml
│       ├── uk.yml
│       ├── de.yml
│       ├── pl.yml
│       └── ru.yml
├── db/
│   └── migrate/
│       └── 001_create_user_telegram_chats.rb
├── lib/bot_notifier/
│   ├── hooks.rb             # Redmine hook listener (view + controller hooks)
│   ├── notifier.rb          # Message builder + delivery logic
│   ├── telegram_sender.rb   # HTTP → Telegram Bot API
│   ├── user_patch.rb        # Virtual attribute telegram_chat_id on User
│   ├── issue_patch.rb
│   └── journal_patch.rb
└── init.rb                  # Plugin registration
```

---

## How it works

```
Issue created/updated
        ↓
Redmine controller hook fires
        ↓
Notifier collects recipients (watchers + assignee + author)
        ↓
For each recipient with a Chat ID:
  → detect user language (Redmine profile setting)
  → build message in that language
  → enqueue SendTelegramJob
        ↓
ActiveJob → TelegramSender → Telegram Bot API
```

---

## License

MIT
