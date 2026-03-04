# =============================================
# HTTP API (GET + POST + PUT)
# =============================================
resource "aws_apigatewayv2_api" "http_api" {
  # Creates an API Gateway v2 "HTTP API" (cheaper/simpler than REST API)
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    # CORS allows React frontend (Amplify) to call this API from a browser
    allow_origins = ["*"]
    # Update: we now allow both GET and POST from browsers
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    # Allow typical headers sent by frontend apps
    allow_headers = ["content-type"]
  }
}

# -----------------------------
# GET /inventory integration
# -----------------------------
resource "aws_apigatewayv2_integration" "get_integration" {
  # Connects API Gateway to a backend target (Lambda in this case)
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY" # Proxy integration = pass request to Lambda, Lambda returns HTTP response
  integration_uri        = aws_lambda_function.get_items.arn
  payload_format_version = "2.0" # HTTP API uses v2 event format by default
}

resource "aws_apigatewayv2_route" "get_inventory" {
  # Creates the route definition users will call
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /inventory"
  # Points the route to the integration created above
  target = "integrations/${aws_apigatewayv2_integration.get_integration.id}"
}
# ==========================================================
# # POST /inventory integration
# ==========================================================
resource "aws_apigatewayv2_integration" "post_integration" {
  # Second integration that targets the POST Lambda function
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_item.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_inventory" {
  # Adds the POST route; without this, POST returns {"message":"Not Found"}
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /inventory"
  target    = "integrations/${aws_apigatewayv2_integration.post_integration.id}"
}

# -----------------------------
# Stage (deployment environment)
# -----------------------------
resource "aws_apigatewayv2_stage" "prod" {
  # Stage name appears in your URL: /prod
  api_id = aws_apigatewayv2_api.http_api.id
  name   = "prod"
  # auto_deploy=true for when any route/integration change goes live immediately after apply
  auto_deploy = true
}
# -----------------------------
# Lambda permissions
# -----------------------------

resource "aws_lambda_permission" "allow_get" {
  # Grants API Gateway permission to invoke the GET Lambda function
  statement_id  = "AllowInvokeGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_items.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_post" {
  # Grants API Gateway permission to invoke the POST Lambda function
  statement_id  = "AllowInvokePost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# -----------------------------
# PUT /inventory
# -----------------------------
resource "aws_apigatewayv2_integration" "put_integration" {
  # Connects PUT route to the update Lambda
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.update_item.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "put_inventory" {
  # Route key must match exactly what you will call: PUT /inventory/c001
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /inventory/{coffeeId}"
  target    = "integrations/${aws_apigatewayv2_integration.put_integration.id}"
}

resource "aws_lambda_permission" "allow_put" {
  # Allows API Gateway to invoke the update Lambda
  statement_id  = "AllowInvokePut"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# =========================================================
# Delete Inventory
# =========================================================
resource "aws_apigatewayv2_integration" "delete_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.delete_item.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_inventory" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE /inventory/{coffeeId}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_integration.id}"
}

resource "aws_lambda_permission" "allow_delete" {
  statement_id  = "AllowInvokeDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}