# Generates an archive from content, a file, or a directory of files.
data "archive_file" "zip_the_python_code-api-gateway" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/lambda_function_request_handler.zip"
}

# Create a lambda function t respond to API request
resource "aws_lambda_function" "api-gateway-lambda" {
 filename                       = "${path.module}/python/lambda_function_request_handler.zip"
 function_name                  = "request-handler-api-lambda-function"
 role                           = aws_iam_role.lambda_role.arn
 handler                        = "lambda_function_request_handler.lambda_handler"
 runtime                        = "python3.8"
 depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_to_iam_role, aws_iam_role_policy_attachment.attach_dynamodb_policy_to_iam_role]
}

# Trigger permissions for API Gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api-gateway-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.get-visitor-count.execution_arn}/*/*"
}

# Define API 
resource "aws_apigatewayv2_api" "get-visitor-count" {
  name          = "cloud-resume-terraform-api"
  protocol_type = "HTTP"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.get-visitor-count.id
  name   = "gateway-stage"
  auto_deploy = true
}

# Integrate API and Lambda
resource "aws_apigatewayv2_integration" "gateway-lambda" {
  api_id           = aws_apigatewayv2_api.get-visitor-count.id
  integration_type = "AWS_PROXY"
  description               = "Map API to Lambda function"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.api-gateway-lambda.arn
  depends_on         = [aws_lambda_permission.apigw]
}

# Define route for API
resource "aws_apigatewayv2_route" "get-route" {
  api_id    = aws_apigatewayv2_api.get-visitor-count.id
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.gateway-lambda.id}"
}

output "api-endpoint" {
  value = aws_apigatewayv2_api.get-visitor-count.api_endpoint
}