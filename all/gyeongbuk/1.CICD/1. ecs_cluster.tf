resource "aws_ecs_cluster" "gyeongbuk-cluster" {
  name = "wsi-ecs"

  tags = {
    Name = "wsi-ecs"
  }
}