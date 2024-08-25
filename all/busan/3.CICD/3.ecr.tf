resource "aws_ecr_repository" "busan-gvn-wsi-ecr" {
  name = "wsi-ecr"
  image_scanning_configuration {
    scan_on_push = true
    }
    tags = {
        Name = "wsi-ecr"
    }
}