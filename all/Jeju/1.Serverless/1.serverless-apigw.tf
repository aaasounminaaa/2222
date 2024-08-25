data "aws_region" "Jeju-api_current" {}

resource "aws_iam_role" "Jeju-dynamodb" {
  name = "Jeju-dynamodb-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
}

resource "aws_api_gateway_rest_api" "Jeju-apigw" {
  name = "serverless-api-gw"
}

resource "aws_api_gateway_resource" "Jeju-apigw_user" {
  parent_id   = aws_api_gateway_rest_api.Jeju-apigw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.Jeju-apigw.id
  path_part   = "user"
}

resource "aws_api_gateway_method" "Jeju-post" {
  rest_api_id    = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id    = aws_api_gateway_resource.Jeju-apigw_user.id
  authorization  = "NONE"
  http_method    = "POST"

  request_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "Jeju-get" {
  rest_api_id    = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id    = aws_api_gateway_resource.Jeju-apigw_user.id
  authorization  = "NONE"
  http_method    = "GET"

  request_parameters = {
    "method.request.querystring.id" = true
  }
}

resource "aws_api_gateway_integration" "Jeju-post" {
  http_method             = aws_api_gateway_method.Jeju-post.http_method
  rest_api_id             = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id             = aws_api_gateway_resource.Jeju-apigw_user.id
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.Jeju-api_current.name}:dynamodb:action/PutItem"
  credentials             = aws_iam_role.Jeju-dynamodb.arn

  request_templates = {
    "application/json" = file("./Jeju/src/post_request.json")
  }
}

resource "aws_api_gateway_integration" "Jeju-get" {
  http_method             = aws_api_gateway_method.Jeju-get.http_method
  rest_api_id             = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id             = aws_api_gateway_resource.Jeju-apigw_user.id
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.Jeju-api_current.name}:dynamodb:action/GetItem"
  credentials             = aws_iam_role.Jeju-dynamodb.arn

  request_templates = {
    "application/json" = file("./Jeju/src/get_request.json")
  }
}

resource "aws_api_gateway_method_response" "Jeju-post" {
  rest_api_id   = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id   = aws_api_gateway_resource.Jeju-apigw_user.id
  http_method   = aws_api_gateway_method.Jeju-post.http_method
  status_code   = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "Jeju-post_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id   = aws_api_gateway_resource.Jeju-apigw_user.id
  http_method   = aws_api_gateway_method.Jeju-post.http_method
  status_code   = "500"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "Jeju-get" {
  rest_api_id   = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id   = aws_api_gateway_resource.Jeju-apigw_user.id
  http_method   = aws_api_gateway_method.Jeju-get.http_method
  status_code   = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "Jeju-post" {
  rest_api_id        = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id        = aws_api_gateway_resource.Jeju-apigw_user.id
  http_method        = aws_api_gateway_method.Jeju-post.http_method
  status_code        = "200"
  selection_pattern  = "200"

  response_templates = {
    "application/json" = file("./Jeju/src/post_response.json")
  }

  depends_on = [aws_api_gateway_integration.Jeju-post]
}

resource "aws_api_gateway_integration_response" "Jeju-post_5xx" {
  rest_api_id        = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id        = aws_api_gateway_resource.Jeju-apigw_user.id
  http_method        = aws_api_gateway_method.Jeju-post.http_method
  status_code        = "500"
  selection_pattern  = "500"

  response_templates = {
    "application/json" = file("./Jeju/src/post_5xx_response.json")
  }

  depends_on = [aws_api_gateway_integration.Jeju-post]
}

resource "aws_api_gateway_integration_response" "Jeju-get" {
  rest_api_id        = aws_api_gateway_rest_api.Jeju-apigw.id
  resource_id        = aws_api_gateway_resource.Jeju-apigw_user.id
  http_method        = aws_api_gateway_method.Jeju-get.http_method
  status_code        = "200"
  selection_pattern  = "200"

  response_templates = {
    "application/json" = file("./Jeju/src/get_response.json")
  }

  depends_on = [aws_api_gateway_integration.Jeju-get]
}

resource "aws_api_gateway_deployment" "Jeju-apigw" {
  depends_on = [
    aws_api_gateway_integration.Jeju-post,
    aws_api_gateway_integration.Jeju-get,
  ]
  
  rest_api_id = aws_api_gateway_rest_api.Jeju-apigw.id
  stage_name  = "v1"
}
