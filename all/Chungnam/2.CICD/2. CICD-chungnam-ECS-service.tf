resource "aws_ecs_service" "wsc2024" {
  name            = "wsc2024-svc"
  cluster         = aws_ecs_cluster.wsc2024.id
  task_definition = aws_ecs_task_definition.wsc2024.arn
  desired_count   = 1

    network_configuration {
      subnets = [ aws_default_subnet.chungnam-default_az1.id,aws_default_subnet.chungnam-default_az2.id ]
      security_groups = [ aws_security_group.ecs-sg.id ]
      assign_public_ip = true
    }
  load_balancer {
    target_group_arn = aws_alb_target_group.wsc2024.arn
    container_name   = "wsc2024-container"
    container_port   = 8080
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

resource "aws_lb" "wsc2024-test" {
  name               = "wsc2024-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wsc2024-lb-sg.id]
  subnets            = [aws_default_subnet.chungnam-default_az1.id,aws_default_subnet.chungnam-default_az2.id]
  tags = {
    Name = "wsc2024-alb"
  }
}

resource "aws_alb_target_group" "wsc2024" {
  name     = "wsc2024-tg"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_default_vpc.chungnam-default.id

  health_check {
    port = 8080
    interval            = 30
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "wsc2024-tg"
  }
}


resource "aws_alb_target_group" "wsc2024-2" {
  name     = "wsc2024-tg-2"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_default_vpc.chungnam-default.id

  health_check {
    port = 8080
    interval            = 30
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "wsc2024-tg-2"
  }
}

resource "aws_alb_listener" "wsc2024-http" {
  load_balancer_arn = aws_lb.wsc2024-test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    forward {
      target_group {
        arn = aws_alb_target_group.wsc2024.arn
      }

      # target_group {
      #   arn = aws_alb_target_group.wsc2024-2.arn
      # }
    }
  }
}

## ALB Security Group
resource "aws_security_group" "wsc2024-lb-sg" {
  name = "wsc2024-alb-sg"
  vpc_id = aws_default_vpc.chungnam-default.id
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
    Name = "wsc2024-alb-sg"
  }
}

resource "aws_security_group" "ecs-sg" {
  name = "wsc2024-ecs-sg"
  vpc_id = aws_default_vpc.chungnam-default.id
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
    tags = {
    Name = "wsc2024-ecs-sg"
  }
}