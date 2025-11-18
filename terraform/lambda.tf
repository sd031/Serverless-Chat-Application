# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          "${aws_dynamodb_table.users.arn}/index/*",
          aws_dynamodb_table.messages.arn,
          "${aws_dynamodb_table.messages.arn}/index/*",
          aws_dynamodb_table.connections.arn,
          "${aws_dynamodb_table.connections.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "arn:aws:execute-api:${var.aws_region}:*:${aws_apigatewayv2_api.websocket.id}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Resource = "${aws_dynamodb_table.messages.arn}/stream/*"
      }
    ]
  })
}

# Lambda Function: Signup
resource "aws_lambda_function" "signup" {
  filename         = "${path.module}/../lambda/auth/signup.zip"
  function_name    = "${local.name_prefix}-signup"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/auth/signup.zip")
  runtime          = "nodejs18.x"
  timeout          = 30

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users.name
    }
  }

  tags = local.common_tags
}

# Lambda Function: Login
resource "aws_lambda_function" "login" {
  filename         = "${path.module}/../lambda/auth/login.zip"
  function_name    = "${local.name_prefix}-login"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/auth/login.zip")
  runtime          = "nodejs18.x"
  timeout          = 30

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users.name
    }
  }

  tags = local.common_tags
}

# Lambda Function: WebSocket Connect
resource "aws_lambda_function" "websocket_connect" {
  filename         = "${path.module}/../lambda/websocket/connect.zip"
  function_name    = "${local.name_prefix}-ws-connect"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/websocket/connect.zip")
  runtime          = "nodejs18.x"
  timeout          = 30

  environment {
    variables = {
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
      USERS_TABLE       = aws_dynamodb_table.users.name
    }
  }

  tags = local.common_tags
}

# Lambda Function: WebSocket Disconnect
resource "aws_lambda_function" "websocket_disconnect" {
  filename         = "${path.module}/../lambda/websocket/disconnect.zip"
  function_name    = "${local.name_prefix}-ws-disconnect"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/websocket/disconnect.zip")
  runtime          = "nodejs18.x"
  timeout          = 30

  environment {
    variables = {
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }

  tags = local.common_tags
}

# Lambda Function: WebSocket Send Message
resource "aws_lambda_function" "websocket_send_message" {
  filename         = "${path.module}/../lambda/websocket/sendMessage.zip"
  function_name    = "${local.name_prefix}-ws-send-message"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/websocket/sendMessage.zip")
  runtime          = "nodejs18.x"
  timeout          = 30

  environment {
    variables = {
      MESSAGES_TABLE    = aws_dynamodb_table.messages.name
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
      USERS_TABLE       = aws_dynamodb_table.users.name
    }
  }

  tags = local.common_tags
}

# Lambda Function: WebSocket Get Messages
resource "aws_lambda_function" "websocket_get_messages" {
  filename         = "${path.module}/../lambda/websocket/getMessages.zip"
  function_name    = "${local.name_prefix}-ws-get-messages"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/websocket/getMessages.zip")
  runtime          = "nodejs18.x"
  timeout          = 30

  environment {
    variables = {
      MESSAGES_TABLE = aws_dynamodb_table.messages.name
    }
  }

  tags = local.common_tags
}

# Lambda Function: Stream Processor
resource "aws_lambda_function" "stream_processor" {
  filename         = "${path.module}/../lambda/streams/processor.zip"
  function_name    = "${local.name_prefix}-stream-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/../lambda/streams/processor.zip")
  runtime          = "nodejs18.x"
  timeout          = 60

  environment {
    variables = {
      CONNECTIONS_TABLE      = aws_dynamodb_table.connections.name
      WEBSOCKET_API_ENDPOINT = "${aws_apigatewayv2_stage.websocket.invoke_url}"
    }
  }

  tags = local.common_tags
}

# Lambda Permissions
resource "aws_lambda_permission" "signup" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.signup.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.auth_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "login" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.auth_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_connect" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_connect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_disconnect" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_disconnect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_send_message" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_send_message.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "websocket_get_messages" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_get_messages.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

# DynamoDB Stream Event Source Mapping
resource "aws_lambda_event_source_mapping" "messages_stream" {
  event_source_arn  = aws_dynamodb_table.messages.stream_arn
  function_name     = aws_lambda_function.stream_processor.arn
  starting_position = "LATEST"
  batch_size        = 10
}
