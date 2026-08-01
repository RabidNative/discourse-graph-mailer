Discourse::Application.routes.append do
  namespace :admin do
    get "graph-mailer/test-email" => "graph_mailer#test_email"
    get "graph-mailer/validate" => "graph_mailer#validate_credentials"
  end
end
