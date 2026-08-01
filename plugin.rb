# frozen_string_literal: true

# name: discourse-graph-mailer
# about: Use Microsoft Graph API for outbound email instead of SMTP
# version: 0.1
# authors: Bryan Martin + Copilot
# url: https://github.com/RabidNative/discourse-graph-mailer

enabled_site_setting :graph_mailer_enabled

after_initialize do
  require_dependency 'email/sender'
  require_relative 'lib/graph_mailer'

  module ::Email
    class Sender
      alias_method :smtp_send, :send

      def send(*args)
        message = args[0]
        opts    = args[1] || {}

        if SiteSetting.graph_mailer_enabled
          GraphMailer.send_via_graph(message)
          message
        else
          smtp_send(*args)
        end
      end
    end
  end
end
  
