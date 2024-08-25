data "aws_region" "busan-gvn-cw_current" {}

resource "aws_iam_role" "busan-gvn-lambda" {
  name = "lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

data "archive_file" "busan-gvn-lambda" {
  type        = "zip"
  source_file = "./busan/2.Governance/src/lambda_function.py"
  output_path = "./busan/2.Governance/src/lambda_function_payload.zip"
}

resource "aws_lambda_function" "busan-gvn-lambda" {
    function_name = "wsi-project-log-function"
    handler = "lambda_function.lambda_handler"
    filename = "./busan/2.Governance/src/lambda_function_payload.zip"
    role = aws_iam_role.busan-gvn-lambda.arn
    timeout = "60"
    source_code_hash = data.archive_file.busan-gvn-lambda.output_base64sha256
    runtime = "python3.12"
    publish = true
}

resource "aws_lambda_permission" "busan-gvn-logging" {
  action = "lambda:InvokeFunction"
  function_name =  aws_lambda_function.busan-gvn-lambda.function_name
  principal = "logs.${data.aws_region.busan-gvn-cw_current.name}.amazonaws.com"
  source_arn = "${aws_cloudwatch_log_group.busan-gvn-trail.arn}:*"

  depends_on = [aws_lambda_function.busan-gvn-lambda]
} 

resource "aws_cloudwatch_log_subscription_filter" "busan-gvn-trail" {
  name            = "trail-filter"
  destination_arn = aws_lambda_function.busan-gvn-lambda.arn
  log_group_name  = aws_cloudwatch_log_group.busan-gvn-trail.name
  filter_pattern  = "{ $.eventName = \"ConsoleLogin\" }"

  depends_on = [aws_lambda_permission.busan-gvn-logging]
}