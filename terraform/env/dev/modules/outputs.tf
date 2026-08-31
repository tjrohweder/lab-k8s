output "cognito_user_pool_id" {
  description = "ID do Cognito User Pool (necessário para o Ingress)"
  value       = aws_cognito_user_pool.dagster_auth.id
}

output "cognito_client_id" {
  description = "ID do Client do Cognito (necessário para o Ingress)"
  value       = aws_cognito_user_pool_client.dagster_client.id
}

output "cognito_domain" {
  description = "Domínio do Cognito"
  value       = aws_cognito_user_pool_domain.dagster_domain.domain
}
