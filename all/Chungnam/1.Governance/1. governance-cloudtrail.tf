data "aws_caller_identity" "chungnam-trail_current" {}

data "aws_partition" "chungnam-trail_current" {}

data "aws_region" "chungnam-trail_current" {}

resource "random_string" "trail_random" {
  length  = 5
  upper   = false
  lower   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "chungnam-trail" {
  bucket        = "wsc2024-trail-logs-${random_string.trail_random.result}"
  force_destroy = true
}

data "aws_iam_policy_document" "chungnam-trail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.chungnam-trail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.chungnam-trail_current.partition}:cloudtrail:${data.aws_region.chungnam-trail_current.name}:${data.aws_caller_identity.chungnam-trail_current.account_id}:trail/wsc2024-CT"]
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
    resources = ["${aws_s3_bucket.chungnam-trail.arn}/prefix/AWSLogs/${data.aws_caller_identity.chungnam-trail_current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.chungnam-trail_current.partition}:cloudtrail:${data.aws_region.chungnam-trail_current.name}:${data.aws_caller_identity.chungnam-trail_current.account_id}:trail/wsc2024-CT"]
    }
  }
}

resource "aws_iam_role" "chungnam-cloudtrail_role" {
  name = "wsi-cloudtrail-role"

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

resource "aws_iam_role_policy_attachment" "chungnam-cloudtrail_role_policy" {
  role       = aws_iam_role.chungnam-cloudtrail_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_s3_bucket_policy" "chungnam-trail" {
  bucket = aws_s3_bucket.chungnam-trail.id
  policy = data.aws_iam_policy_document.chungnam-trail.json
}

resource "aws_cloudtrail" "chungnam-trail" {
  depends_on = [aws_s3_bucket_policy.chungnam-trail, aws_cloudwatch_log_group.chungnam-trail]

  name                          = "wsc2024-CT"
  s3_bucket_name                = aws_s3_bucket.chungnam-trail.id
  s3_key_prefix                 = "prefix"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.chungnam-trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.chungnam-cloudtrail_role.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type             = "All"
    include_management_events   = true
  }
  tags = {
    Name = "wsc2024-CT"
  }
}