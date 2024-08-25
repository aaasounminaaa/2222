resource "aws_ecr_repository" "daejeon-ecr" {
  name = "wsi-ecr"
  image_tag_mutability = "MUTABLE"

    tags = {
        Name = "wsi-ecr"
    } 
}