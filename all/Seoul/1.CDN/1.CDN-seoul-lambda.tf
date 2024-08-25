locals {
  cdn_code_path = "./Seoul/cdn-code"
  code_path = "./Seoul/code"
  filepath = "./Seoul/content"
  js_path = "./Seoul/code"
}

data "aws_iam_policy_document" "seoul-lambda_assume_role" {
  provider = aws.us-east-1
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Inline Policy Document
data "aws_iam_policy_document" "seoul-lambda_policy" {
  provider = aws.us-east-1
  statement {
    effect = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "logs:CreateLogStream",
      "iam:CreateServiceLinkedRole",
      "logs:DescribeLogStreams",
      "lambda:GetFunction",
      "cloudfront:UpdateDistribution",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "lambda:EnableReplication"
    ]
    resources = ["*"]
  }
}

# IAM Role
resource "aws_iam_role" "seoul-lambda" {
  provider = aws.us-east-1
  name               = "seoul-cdn-Lambda-role"
  assume_role_policy = data.aws_iam_policy_document.seoul-lambda_assume_role.json
}

# IAM Role Policy
resource "aws_iam_role_policy" "seoul-lambda_policy" {
  provider = aws.us-east-1
  name   = "seoul-cdn-lambda-policy"
  role   = aws_iam_role.seoul-lambda.id
  policy = data.aws_iam_policy_document.seoul-lambda_policy.json
}


resource "aws_lambda_function" "seoul-lambda" {
    provider = aws.us-east-1
    filename = "${local.cdn_code_path}/lambda_function_js_payload.zip"
    function_name = "wsi-resizing-function"
    role = aws_iam_role.seoul-lambda.arn
    handler = "index.handler"
    timeout = "30"
    source_code_hash = filebase64sha256("${local.cdn_code_path}/lambda_function_js_payload.zip") 
    runtime = "nodejs20.x"
    publish  = true
}