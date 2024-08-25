resource "aws_ecr_repository" "gyeongbuk_ecr" {
  name = "gyeongbuk-ecr"
  image_tag_mutability = "IMMUTABLE"

    tags = {
        Name = "gyeongbuk-ecr"
    }
}