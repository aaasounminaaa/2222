resource "aws_codecommit_repository" "busan-cicd-repo" {
  repository_name = "wsi-repo"
  description     = "This is the Sample App Repository"
}

resource "aws_s3_bucket" "busan-app" {
  bucket = "busan-app-${random_string.busan_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "busan-appspec" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/appspec.yml"
  source = "./busan/3.CICD/src/appspec.yml"
  etag   = filemd5("./busan/3.CICD/src/appspec.yml")
  content_type = "application/vnd.yaml"
}
resource "aws_s3_object" "busan-buildspec" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/buildspec.yaml"
  source = "./busan/3.CICD/src/buildspec.yaml"
  etag   = filemd5("./busan/3.CICD/src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}
resource "aws_s3_object" "busan-Docker" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/Dockerfile"
  source = "./busan/3.CICD/src/Dockerfile"
  etag   = filemd5("./busan/3.CICD/src/Dockerfile")
}
resource "aws_s3_object" "busan-app" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/src/app.py"
  source = "./busan/3.CICD/src/src/app.py"
  etag   = filemd5("./busan/3.CICD/src/src/app.py")
}

resource "aws_s3_object" "busan-ApplicationStop" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/scripts/ApplicationStop.sh"
  source = "./busan/3.CICD/src/scripts/ApplicationStop.sh"
  etag   = filemd5("./busan/3.CICD/src/scripts/ApplicationStop.sh")
}

resource "aws_s3_object" "busan-BeforeInstall" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/scripts/BeforeInstall.sh"
  source = "./busan/3.CICD/src/scripts/BeforeInstall.sh"
  etag   = filemd5("./busan/3.CICD/src/scripts/BeforeInstall.sh")
}

resource "aws_s3_object" "busan-ApplicationStart" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/scripts/ApplicationStart.sh"
  source = "./busan/3.CICD/src/scripts/ApplicationStart.sh"
  etag   = filemd5("./busan/3.CICD/src/scripts/ApplicationStart.sh")
}

resource "aws_s3_object" "busan-AfterInstall" {
  bucket = aws_s3_bucket.busan-app.id
  key    = "/scripts/AfterInstall.sh"
  source = "./busan/3.CICD/src/scripts/AfterInstall.sh"
  etag   = filemd5("./busan/3.CICD/src/scripts/AfterInstall.sh")
}