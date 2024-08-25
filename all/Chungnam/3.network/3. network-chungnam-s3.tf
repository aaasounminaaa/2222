resource "random_string" "chungnam-bucket_random" {
  length           = 4
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

resource "aws_s3_bucket" "chungnam-source" {
  bucket   = "gm-${random_string.chungnam-bucket_random.result}"
}