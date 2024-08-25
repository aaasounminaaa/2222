resource "random_string" "gyeongbuk-ecs_random" {
  length  = 5
  upper   = false
  lower   = false
  numeric = true
  special = false
}

resource "aws_security_group" "gyeongbuk-ecs" {
  name = "gyeongbuk-ecs-sg"
  vpc_id = "${var.vpc}"
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
    tags = {
    Name = "gyeongbuk-ecs-sg"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

data "aws_iam_policy_document" "gyeongbuk-ecs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gyeongbuk-ecs" {
  name               = "gyeongbuk-role-ecs"
  assume_role_policy = data.aws_iam_policy_document.gyeongbuk-ecs.json
}

resource "aws_iam_role_policy_attachment" "gyeongbuk-ecs" {
  role       = aws_iam_role.gyeongbuk-ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "gyeongbuk-ecs" {
  name = "gyeongbuk-ecs-profile"
  role = aws_iam_role.gyeongbuk-ecs.name
}

data "aws_ssm_parameter" "gyeongbuk-ecs_latest_ami_2023" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_configuration" "gyeongbuk-ecs" {
  image_id             = data.aws_ssm_parameter.gyeongbuk-ecs_latest_ami_2023.value
  iam_instance_profile = aws_iam_instance_profile.gyeongbuk-ecs.name
  security_groups      = [aws_security_group.gyeongbuk-ecs.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.gyeongbuk-cluster.name} >> /etc/ecs/ecs.config"
  instance_type        = "t3.medium"
}

resource "aws_autoscaling_group" "gyeongbuk-ecs" {
  name                      = "wsi-ecs-s"
  vpc_zone_identifier       = [
    "${var.private_a}",
    "${var.private_b}",
  ]
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 10
  health_check_grace_period = 300
  health_check_type         = "EC2"

  launch_configuration = aws_launch_configuration.gyeongbuk-ecs.name

  protect_from_scale_in = true

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "wsi-ecs-service"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "gyeongbuk-capacity" {
  name = "ec2_capacity-${random_string.gyeongbuk-ecs_random.result}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.gyeongbuk-ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "DISABLED"
      target_capacity           = 60
    }
  }
}