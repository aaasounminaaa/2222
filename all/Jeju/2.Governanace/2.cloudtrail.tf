data "aws_caller_identity" "Jeju-gvn-trail_current" {}

data "aws_partition" "Jeju-gvn-trail_current" {}

data "aws_region" "Jeju-gvn-trail_current" {}

resource "random_string" "Jeju-gvn-trail_random" {
  length  = 5
  upper   = false
  lower   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "Jeju-gvn-trail" {
  bucket        = "cg-trail-logs-${random_string.Jeju-gvn-trail_random.result}"
  force_destroy = true
}

data "aws_iam_policy_document" "Jeju-gvn-trail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.Jeju-gvn-trail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.Jeju-gvn-trail_current.partition}:cloudtrail:${data.aws_region.Jeju-gvn-trail_current.name}:${data.aws_caller_identity.Jeju-gvn-trail_current.account_id}:trail/cg-trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.Jeju-gvn-trail.arn}/prefix/AWSLogs/${data.aws_caller_identity.Jeju-gvn-trail_current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.Jeju-gvn-trail_current.partition}:cloudtrail:${data.aws_region.Jeju-gvn-trail_current.name}:${data.aws_caller_identity.Jeju-gvn-trail_current.account_id}:trail/cg-trail"]
    }
  }
}

resource "aws_iam_role" "Jeju-gvn-cloudtrail_role" {
  name = "cg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "Jeju-gvn-cloudtrail_role_policy" {
  role       = aws_iam_role.Jeju-gvn-cloudtrail_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_s3_bucket_policy" "Jeju-gvn-trail" {
  bucket = aws_s3_bucket.Jeju-gvn-trail.id
  policy = data.aws_iam_policy_document.Jeju-gvn-trail.json
}

resource "aws_cloudwatch_log_group" "Jeju-gvn-trail" {
  name = "cg-logs"

  tags = {
    Name = "cg-logs"
  }
}

resource "aws_cloudtrail" "Jeju-gvn-trail" {
  depends_on = [aws_s3_bucket_policy.Jeju-gvn-trail, aws_cloudwatch_log_group.Jeju-gvn-trail]

  name                          = "cg-trail"
  s3_bucket_name                = aws_s3_bucket.Jeju-gvn-trail.id
  s3_key_prefix                 = "prefix"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.Jeju-gvn-trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.Jeju-gvn-cloudtrail_role.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type             = "All"
    include_management_events   = true
  }

  tags = {
    Name = "cg-trail"
  }
}


resource "aws_cloudwatch_log_metric_filter" "Jeju-gvn-trail" {
  name           = "ssm-connection"
  pattern        = "%StartSession%"
  log_group_name = aws_cloudwatch_log_group.Jeju-gvn-trail.name

  metric_transformation {
    namespace = "ssm-connection"
    name      = "ssm-connection"
    value     = "1"
  }
}

resource "aws_cloudwatch_dashboard" "Jeju-gvn-tail" {
  dashboard_name = "cg-dashboard"
  dashboard_body = "${file("./Jeju/src/widgets.json")}"
}

resource "aws_cloudwatch_query_definition" "Jeju-gvn-trail" {
  name            = "SSMConnectionQuery"
  log_group_names = [aws_cloudwatch_log_group.Jeju-gvn-trail.name]
  query_string    = "${file("./Jeju/src/ssm_connection_query.txt")}"
}