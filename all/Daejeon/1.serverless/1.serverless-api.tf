data "aws_region" "daejeon_api_current" {}

resource "aws_iam_role" "daejeon-dynamodb" {
  name = "daejeon-dynamodb-role"
  
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

resource "aws_api_gateway_rest_api" "daejeon-apigw" {
  name = "wsi-api"
}

resource "aws_api_gateway_resource" "daejeon-apigw_user" {
  parent_id   = aws_api_gateway_rest_api.daejeon-apigw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  path_part   = "user"
}

resource "aws_api_gateway_resource" "daejeon-apigw_healthcheck" {
  parent_id   = aws_api_gateway_rest_api.daejeon-apigw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  path_part   = "healthz"
}

resource "aws_api_gateway_request_validator" "daejeon-validate_body" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  name        = "Validate Body"
  validate_request_body = true
  validate_request_parameters = false
}

resource "aws_api_gateway_method" "daejeon-api-post" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  authorization = "NONE"
  http_method = "POST"
  request_validator_id = aws_api_gateway_request_validator.daejeon-validate_body.id

  request_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "daejeon-api-get" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  authorization = "NONE"
  http_method = "GET"

  request_parameters = {
    "method.request.querystring.name" = true
  }
}

resource "aws_api_gateway_method" "daejeon-api-delete" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  authorization = "NONE"
  http_method = "DELETE"

  request_parameters = {
    "method.request.querystring.name" = true
  }
}

resource "aws_api_gateway_method" "daejeon-api-healthcheck" {
  rest_api_id   = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id   = aws_api_gateway_resource.daejeon-apigw_healthcheck.id
  authorization = "NONE"
  http_method   = "GET"
}

resource "aws_api_gateway_integration" "daejeon-api-post" {
  http_method = aws_api_gateway_method.daejeon-api-post.http_method
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${data.aws_region.daejeon_api_current.name}:dynamodb:action/PutItem"
  credentials = aws_iam_role.daejeon-dynamodb.arn

  request_templates = {
    "application/json" = "${file("./Daejeon/src/post_request.json")}"
  }
}

resource "aws_api_gateway_integration" "daejeon-api-get" {
  http_method = aws_api_gateway_method.daejeon-api-get.http_method
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${data.aws_region.daejeon_api_current.name}:dynamodb:action/GetItem"
  credentials = aws_iam_role.daejeon-dynamodb.arn

  request_templates = {
    "application/json" = "${file("./Daejeon/src/get_request.json")}"
  }
}

resource "aws_api_gateway_integration" "daejeon-api-delete" {
  http_method = aws_api_gateway_method.daejeon-api-delete.http_method
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${data.aws_region.daejeon_api_current.name}:dynamodb:action/DeleteItem"
  credentials = aws_iam_role.daejeon-dynamodb.arn

  request_templates = {
    "application/json" = "${file("./Daejeon/src/delete_request.json")}"
  }
}

resource "aws_api_gateway_integration" "daejeon-api-healthcheck" {
  rest_api_id          = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id          = aws_api_gateway_resource.daejeon-apigw_healthcheck.id
  http_method          = aws_api_gateway_method.daejeon-api-healthcheck.http_method
  type                 = "MOCK"

  request_templates = {
    "application/json" = "${file("./Daejeon/src/healthcheck_request.json")}"
  }
}

resource "aws_api_gateway_method_response" "daejeon-api-post" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  http_method = aws_api_gateway_method.daejeon-api-post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "daejeon-api-get" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  http_method = aws_api_gateway_method.daejeon-api-get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "daejeon-api-delete" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  http_method = aws_api_gateway_method.daejeon-api-delete.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "daejeon-api-healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_healthcheck.id
  http_method = aws_api_gateway_method.daejeon-api-healthcheck.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "daejeon-api-post" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  http_method = aws_api_gateway_method.daejeon-api-post.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./Daejeon/src/post_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.daejeon-api-post]
}

resource "aws_api_gateway_integration_response" "daejeon-api-get" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  http_method = aws_api_gateway_method.daejeon-api-get.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./Daejeon/src/get_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.daejeon-api-get]
}

resource "aws_api_gateway_integration_response" "daejeon-api-delete" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_user.id
  http_method = aws_api_gateway_method.daejeon-api-delete.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./Daejeon/src/delete_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.daejeon-api-delete]
}

resource "aws_api_gateway_integration_response" "daejeon-api-healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  resource_id = aws_api_gateway_resource.daejeon-apigw_healthcheck.id
  http_method = aws_api_gateway_method.daejeon-api-healthcheck.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./Daejeon/src/healthcheck_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.daejeon-api-healthcheck]
}

resource "aws_api_gateway_deployment" "daejeon-apigw" {
  depends_on = [
    aws_api_gateway_integration.daejeon-api-post,
    aws_api_gateway_integration.daejeon-api-get,
    aws_api_gateway_integration.daejeon-api-delete
  ]
  
  rest_api_id = aws_api_gateway_rest_api.daejeon-apigw.id
  stage_name = "v1"
}