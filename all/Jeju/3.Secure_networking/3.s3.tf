resource "random_string" "J-company-bucket_random" {
  length           = 7
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

resource "aws_s3_bucket" "J-company-source" {
  bucket   = "j-s3-bucket-${random_string.J-company-bucket_random.result}-original"
}

resource "aws_s3_bucket_versioning" "J-company-source" {
  bucket   = aws_s3_bucket.J-company-source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "J-company-backup" {
  bucket   = "j-s3-bucket-${random_string.J-company-bucket_random.result}-backup"
}

resource "aws_s3_bucket_notification" "J-company-bucket_notification" {
  bucket = aws_s3_bucket.J-company-backup.id

  queue {
    queue_arn     = aws_sqs_queue.J-company-queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "2024/"
  }
  depends_on = [ aws_s3_bucket.J-company-backup, aws_sqs_queue.J-company-queue ]
}

resource "aws_s3_bucket_versioning" "J-company-backup" {
  bucket   = aws_s3_bucket.J-company-backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "J-company-folder1" {
    bucket = aws_s3_bucket.J-company-source.id
    key    = "2024/"
}

resource "aws_s3_object" "J-company-folder2" {
    bucket = aws_s3_bucket.J-company-backup.id
    key    = "2024/"
}

data "aws_iam_policy_document" "J-company-assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "J-company-replication" {
  name               = "Jeju-role-replication-12345"
  assume_role_policy = data.aws_iam_policy_document.J-company-assume_role.json
}

data "aws_iam_policy_document" "J-company-replication" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.J-company-source.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.J-company-source.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.J-company-backup.arn}/*"]
  }
}

resource "aws_iam_policy" "J-company-replication" {
  name   = "Jeju-policy-replication-${random_string.J-company-bucket_random.result}"
  policy = data.aws_iam_policy_document.J-company-replication.json
}

resource "aws_iam_role_policy_attachment" "J-company-replication" {
  role       = aws_iam_role.J-company-replication.name
  policy_arn = aws_iam_policy.J-company-replication.arn
}

### Replication Configuration (Seoul Source to USA Destination) ###
resource "aws_s3_bucket_replication_configuration" "J-company-replication" {
  depends_on = [aws_s3_bucket_versioning.J-company-source, aws_s3_bucket_versioning.J-company-backup]

  role   = aws_iam_role.J-company-replication.arn
  bucket = aws_s3_bucket.J-company-source.id

  rule {
    id     = "ReplicationRule"
    status = "Enabled"

    filter {
      prefix = "2024/"
    }
    destination {
      bucket        = aws_s3_bucket.J-company-backup.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }
}