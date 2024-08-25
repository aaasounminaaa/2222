resource "aws_ecs_cluster" "wsc2024" {
  name = "wsc2024-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "wsc2024" {
  cluster_name = aws_ecs_cluster.wsc2024.name

  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}