resource "aws_cognito_user_pool" "dagster_auth" {
  name = "dagster-auth-pool"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_domain" "dagster_domain" {
  domain       = "dagster-tjrohweder"
  user_pool_id = aws_cognito_user_pool.dagster_auth.id
}

resource "aws_cognito_user_pool_client" "dagster_client" {
  name                                 = "dagster-alb-client"
  user_pool_id                         = aws_cognito_user_pool.dagster_auth.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["https://dagster.${var.domain.name}/oauth2/idpresponse"]
}
