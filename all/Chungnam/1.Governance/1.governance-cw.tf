resource "aws_cloudwatch_log_group" "chungnam-trail" {
  name = "wsc2024-gvn-LG"

  tags = {
    Name = "wsc2024-gvn-LG"
  }
}

resource "aws_cloudwatch_log_subscription_filter" "chungnam-governance-filter" {
  name            = "chungnam-gvn-filter"
  log_group_name  = aws_cloudwatch_log_group.chungnam-trail.name
  filter_pattern  = "{ $.eventName = \"AttachRolePolicy\" }"
  destination_arn = aws_lambda_function.governance-chungname-lambda.arn
}

resource "aws_cloudwatch_log_metric_filter" "chungnam-trail-metrics" {
  log_group_name = aws_cloudwatch_log_group.chungnam-lambda_log_group.name
  name = "chungnam-gvn-mt-fileter"
  # 패턴 정의
  pattern = "%good%"
  # 지표 할당
  metric_transformation {
    name      = "gvn"
    namespace = "gvn"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "metric-alarms" {
  # 지표
  alarm_name        = "wsc2024-gvn-alarm"
  metric_name       = aws_cloudwatch_log_metric_filter.chungnam-trail-metrics.metric_transformation[0].name
  namespace         = aws_cloudwatch_log_metric_filter.chungnam-trail-metrics.metric_transformation[0].namespace
  # 조건
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "30"
  statistic           = "Minimum"
  threshold           = "0.9"
}