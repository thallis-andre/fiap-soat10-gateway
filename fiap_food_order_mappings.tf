## VPC Link Connection
resource "aws_apigatewayv2_integration" "fiap_food_order" {
  api_id             = aws_apigatewayv2_api.fiap_food.id
  integration_uri    = var.aws_eks_lb_listener_order_service
  integration_method = "ANY"
  integration_type   = "HTTP_PROXY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.fiap_food_eks.id
}

## Route Mappings
resource "aws_apigatewayv2_route" "fiap_food_order_create" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "POST /fiap-food-orders/v1/orders"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_find" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "GET /fiap-food-orders/v1/orders"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_get" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "GET /fiap-food-orders/v1/orders/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_add_item" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "PUT /fiap-food-orders/v1/orders/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_remove_item" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "PATCH /fiap-food-orders/v1/orders/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_checkout" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "POST /fiap-food-orders/v1/orders/{id}/checkout"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_complete" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "POST /fiap-food-orders/v1/orders/{id}/complete"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_follow_up" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "GET /fiap-food-orders/v1/orders-follow-up"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_item_create" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "POST /fiap-food-orders/v1/items"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_item_find" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "GET /fiap-food-orders/v1/items"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_item_get" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "GET /fiap-food-orders/v1/items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}

resource "aws_apigatewayv2_route" "fiap_food_order_item_update" {
  api_id    = aws_apigatewayv2_api.fiap_food.id
  route_key = "PUT /fiap-food-orders/v1/items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.fiap_food_order.id}"
}
