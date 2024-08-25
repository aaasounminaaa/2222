resource "aws_appautoscaling_target" "gyeongbuk-tg" {
  max_capacity = 8
  min_capacity = 2
  resource_id = "service/${aws_ecs_cluster.gyeongbuk-cluster.name}/${aws_ecs_service.gyeongbuk-svc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "gyeongbuk-memory" {
  name               = "memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gyeongbuk-tg.resource_id
  scalable_dimension = aws_appautoscaling_target.gyeongbuk-tg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.gyeongbuk-tg.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
  }
}

resource "aws_appautoscaling_policy" "gyeongbuk-cpu" {
  name = "cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.gyeongbuk-tg.resource_id
  scalable_dimension = aws_appautoscaling_target.gyeongbuk-tg.scalable_dimension
  service_namespace = aws_appautoscaling_target.gyeongbuk-tg.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}