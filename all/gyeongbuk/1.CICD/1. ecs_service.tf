resource "aws_ecs_service" "gyeongbuk-svc" {
  name            = "wsi-ecs-s"
  cluster         = aws_ecs_cluster.gyeongbuk-cluster.id
  task_definition = aws_ecs_task_definition.gyeongbuk-td.arn
  desired_count   = 2
  health_check_grace_period_seconds = 0
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets = [
      "${var.private_a}",
      "${var.private_a}"
    ]

    security_groups = [
      aws_security_group.gyeongbuk-ecs.id
    ]

    assign_public_ip = false
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.gyeongbuk-CICD-1-lb.arn
    container_name   = "wsi-container"
    container_port   = 80
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [ap-northeast-2a, ap-northeast-2b]"
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.gyeongbuk-capacity.name
    weight            = 100  # weight 값을 추가했습니다.
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, capacity_provider_strategy]
  }
}

resource "aws_ecs_cluster_capacity_providers" "gyeongbuk-capacity" {
  cluster_name = aws_ecs_cluster.gyeongbuk-cluster.name

  capacity_providers = [
    aws_ecs_capacity_provider.gyeongbuk-capacity.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.gyeongbuk-capacity.name
    weight            = 100  # default_capacity_provider_strategy에서도 weight 값을 추가했습니다.
  }
}
