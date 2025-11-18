output "website_url" {
  description = "URL of the S3 hosted website"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "auth_api_url" {
  description = "URL of the authentication API"
  value       = aws_api_gateway_stage.auth_api.invoke_url
}

output "websocket_url" {
  description = "URL of the WebSocket API"
  value       = aws_apigatewayv2_stage.websocket.invoke_url
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "users_table_name" {
  description = "Name of the DynamoDB users table"
  value       = aws_dynamodb_table.users.name
}

output "messages_table_name" {
  description = "Name of the DynamoDB messages table"
  value       = aws_dynamodb_table.messages.name
}

output "connections_table_name" {
  description = "Name of the DynamoDB connections table"
  value       = aws_dynamodb_table.connections.name
}
