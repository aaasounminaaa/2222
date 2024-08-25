locals {
  code_path = "./Daejeon/daejeon-code"
}
data "archive_file" "daejeon-lambda" {
  type        = "zip"
  source_file = "${local.code_path}/lambda_function.py"
  output_path = "${local.code_path}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "daejeon-lambda" {
    filename = "./${local.code_path}/lambda_function_payload.zip"
    function_name = "wsi-config-function"
    role = "${var.lambda_role}"
    handler = "lambda_function.lambda_handler"
    timeout = "5"
    source_code_hash = data.archive_file.daejeon-lambda.output_base64sha256
    runtime = "python3.12"
}

resource "aws_lambda_permission" "daejeon-config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daejeon-lambda.arn
  principal     = "config.amazonaws.com"
}