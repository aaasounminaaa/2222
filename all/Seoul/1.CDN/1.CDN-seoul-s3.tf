### S3
### Source Bucket and Versioning (Seoul) ###
resource "random_string" "bucket_random" {
  length           = 4
  upper   = false
  lower   = true
  numeric  = false
  special = false
}
resource "aws_s3_bucket" "seoul-source" {
  bucket   = "wsi-static-${random_string.bucket_random.result}"
}

resource "aws_s3_object" "seoul-static" {
  bucket = aws_s3_bucket.seoul-source.id
  key    = "index.html"
  source = "${local.filepath}/index.html"
  etag   = filemd5("${local.filepath}/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "seoul-glass" {
  bucket = aws_s3_bucket.seoul-source.id
  key    = "images/glass.jpg"
  source = "${local.filepath}/images/glass.jpg"
  etag   = filemd5("${local.filepath}/images/glass.jpg")
  content_type = "image/jpeg"
}

resource "aws_s3_object" "seoul-hamster" {
  bucket = aws_s3_bucket.seoul-source.id
  key    = "images/hamster.jpg"
  source = "${local.filepath}/images/hamster.jpg"
  etag   = filemd5("${local.filepath}/images/hamster.jpg")
  content_type = "image/jpeg"
}

resource "aws_s3_object" "seoul-librany" {
  bucket = aws_s3_bucket.seoul-source.id
  key    = "images/library.jpg"
  source = "${local.filepath}/images/library.jpg"
  etag   = filemd5("${local.filepath}/images/library.jpg")
  content_type = "image/jpeg"
}

resource "aws_s3_object" "seoul-folder1" {
    bucket = aws_s3_bucket.seoul-source.id
    key    = "dev/"
}

resource "aws_s3_bucket_policy" "seoul-cdn-oac-bucket-policy" {
  bucket = aws_s3_bucket.seoul-source.id
  policy = data.aws_iam_policy_document.seoul-static_s3_policy.json
}

data "aws_iam_policy_document" "seoul-static_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.seoul-source.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.seoul-cf_dist.arn]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "seoul-source" {
  bucket = aws_s3_bucket.seoul-source.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "seoul-source" {
  bucket   = aws_s3_bucket.seoul-source.id
  versioning_configuration {
    status = "Enabled"
  }
}