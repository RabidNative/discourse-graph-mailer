# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class GraphMailer
  TOKEN_URL = "https://login.microsoftonline.com/%{tenant_id}/oauth2/v2.0/token"
  SENDMAIL_URL = "https://graph.microsoft.com/v1.0/users/%{upn}/sendMail"

  def self.send_via_graph(mail)
    token = fetch_token
    payload = build_payload(mail)

    uri = URI.parse(SENDMAIL_URL % { upn: SiteSetting.graph_mailer_user_principal_name })
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.request_uri)
    req['Authorization'] = "Bearer #{token}"
    req['Content-Type'] = 'application/json'
    req.body = JSON.dump(payload)

    response = http.request(req)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("GraphMailer sendMail failed: #{response.code} #{response.body}")
      raise "GraphMailer sendMail failed: #{response.code}"
    end

    true
  end

  def self.fetch_token
    uri = URI.parse(TOKEN_URL % { tenant_id: SiteSetting.graph_mailer_tenant_id })
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.request_uri)
    req.set_form_data(
      'client_id' => SiteSetting.graph_mailer_client_id,
      'client_secret' => SiteSetting.graph_mailer_client_secret,
      'scope' => 'https://graph.microsoft.com/.default',
      'grant_type' => 'client_credentials'
    )

    response = http.request(req)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("GraphMailer token fetch failed: #{response.code} #{response.body}")
      raise "GraphMailer token fetch failed: #{response.code}"
    end

    JSON.parse(response.body)['access_token']
  end

  def self.build_payload(mail)
    to_recipients = Array(mail.to).map do |addr|
      { "emailAddress" => { "address" => addr } }
    end

    cc_recipients = Array(mail.cc).map do |addr|
      { "emailAddress" => { "address" => addr } }
    end

    bcc_recipients = Array(mail.bcc).map do |addr|
      { "emailAddress" => { "address" => addr } }
    end

    body_html = mail.html_part&.body&.decoded || mail.body.decoded
    body_text = mail.text_part&.body&.decoded

    message = {
      "subject" => mail.subject,
      "body" => {
        "contentType" => "html" : "text",
        "content" => body_html || body_text
      },
      "from" => {
        "emailAddress" => {
          "address" => SiteSetting.graph_mailer_from_address
        }
      },
      "replyTo" => [
        {
          "emailAddress" => {
            "address" => SiteSetting.graph_mailer_from_address
          }
        }
      ],
      "toRecipients" => to_recipients
    }

    message["ccRecipients"] = cc_recipients if cc_recipients.any?
    message["bccRecipients"] = bcc_recipients if bcc_recipients.any?

    {
      "message" => message,
      "saveToSentItems" => false
    }
  end
end
