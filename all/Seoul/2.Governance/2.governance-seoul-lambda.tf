locals {
  js_path = "./Seoul/code"
  seoul_code_path = "./Seoul/code"
}

data "aws_caller_identity" "seoul-gvn-current" {}

data "archive_file" "seoul-lambda" {
  type        = "zip"
  source_file = "${local.seoul_code_path}/lambda_function.py"
  output_path = "${local.seoul_code_path}lambda_function_payload.zip"
}

resource "aws_lambda_function" "seoul-governance-lambda" {
    filename         = data.archive_file.seoul-lambda.output_path
    function_name = "wsi-sg-function"
    role = "${var.lambda_role}"
    handler = "lambda_function.lambda_handler"
    timeout = "5"
    source_code_hash = data.archive_file.seoul-lambda.output_base64sha256
    runtime = "python3.12"
    environment {
      variables = {
        ACCOUNT_ID = data.aws_caller_identity.seoul-gvn-current.user_id
      }
    }
}

resource "aws_lambda_permission" "seoul-governance-permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.seoul-governance-lambda.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}