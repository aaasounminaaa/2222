resource "aws_ecr_repository" "wsc2024-repo" {
  name = "wsc2024-repo"
  # image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
    }
    tags = {
        Name = "wsc2024-repo"
    }
}