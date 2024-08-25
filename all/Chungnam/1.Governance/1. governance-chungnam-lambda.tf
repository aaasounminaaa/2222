locals {
  code_path = "./Chungnam/code"
}

data "archive_file" "governance-chungname-lambda" {
  type        = "zip"
  source_file = "${local.code_path}/lambda_function.py"
  output_path = "${local.code_path}/lambda_function_payload.zip"
}

resource "aws_cloudwatch_log_group" "chungnam-lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.governance-chungname-lambda.function_name}"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_lambda_function" "governance-chungname-lambda" {
  filename         = data.archive_file.governance-chungname-lambda.output_path
  function_name    = "wsc2024-gvn-Lambda"
  role             = var.lambda_role
  handler          = "lambda_function.lambda_handler"
  timeout          = 5
  source_code_hash = data.archive_file.governance-chungname-lambda.output_base64sha256
  runtime          = "python3.9"
}

resource "aws_lambda_permission" "default" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.governance-chungname-lambda.function_name
  principal     = "logs.${data.aws_region.chungnam-trail_current.name}.amazonaws.com"
  source_arn    = format("%s:*", aws_cloudwatch_log_group.chungnam-trail.arn)
}