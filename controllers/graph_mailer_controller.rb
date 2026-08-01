class ::GraphMailerController < ::Admin::AdminController
  requires_plugin 'discourse-graph-mailer'

  def test_email
    to = params[:to] || SiteSetting.graph_mailer_test_address

    message = Mail::Message.new(
      to: to,
      from: SiteSetting.graph_mailer_from_address,
      subject: "Graph Mailer Test",
      html_part: "<p>This is a test email sent through Microsoft Graph.</p>"
    )

    begin
      GraphMailer.send_via_graph(message)
      render_json_dump(success: true)
    rescue => e
      render_json_error(e.message)
    end
  end

  def validate_credentials
    begin
      GraphMailer.fetch_token
      render_json_dump(success: true)
    rescue => e
      render_json_error(e.message)
    end
  end
end
