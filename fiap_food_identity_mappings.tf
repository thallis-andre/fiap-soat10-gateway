data "terraform_remote_state" "fiap_food_identity" {
  backend = "s3"
  config = {
    bucket = "fiap-f4-soat10"
    key    = "global/s3/auth-lambda.tfstate"
    region = "us-east-1"
  }
}

resource "aws_apigatewayv2_integration" "fiap_food_identity_integration" {
  api_id           = aws_apigatewayv2_api.fiap_food.id
  integration_type = "AWS_PROXY"
  integration_uri  = data.terraform_remote_state.fiap_food_identity.outputs.fiap_food_identity_invoke_arn
}

resource "aws_apigatewayv2_route" "proxy_handler" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "POST /identity"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_identity_integration.id}"
}

resource "aws_lambda_permission" "api_gtw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.fiap_food_identity.outputs.fiap_food_identity_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.fiap_food.execution_arn}/*/*/identity"
}
