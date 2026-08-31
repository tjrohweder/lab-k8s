output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.dagster_auth.id
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.dagster_client.id
}

output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.dagster_domain.domain
}
