# frozen_string_literal: true

require 'net/http'
require 'json'

module BotNotifier
  module TelegramSender
    API_BASE = 'https://api.telegram.org'

    def self.send_message(chat_id, text)
      token = Setting.plugin_bot_notifier[:bot_token].to_s.strip
      return if token.blank?

      uri = URI("#{API_BASE}/bot#{token}/sendMessage")
      payload = { chat_id: chat_id, text: text, parse_mode: 'HTML' }.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = payload

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "[BotNotifier] Telegram error #{response.code}: #{response.body}"
      end
    rescue => e
      Rails.logger.error "[BotNotifier] send_message failed for chat_id=#{chat_id}: #{e.message}"
    end
  end
end
