resource "aws_lb" "gyeongbuk-CICD-lb" {
  name               = "wsi-alb-ci"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gyeongbuk-CICD-lb-SG.id]
  subnets            = ["${var.public_a}", "${var.public_b}"]

  tags = {
    Name = "wsi-alb-ci"
  }
}

resource "aws_lb_listener" "gyeongbuk-CICD-lb" {
  load_balancer_arn = aws_lb.gyeongbuk-CICD-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gyeongbuk-CICD-1-lb.arn
    type             = "forward"

    fixed_response {
      content_type = "text/plain"
      message_body = "404 Page Error"
      status_code  = "404"
    }
  }
}

resource "aws_alb_target_group" "gyeongbuk-CICD-1-lb" {
  name     = "wsi-alb-1-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = "${var.vpc}"
  deregistration_delay = 0

  health_check {
    path = "/"
    port = 80
    timeout = 2
    interval = 5
    unhealthy_threshold = 2
    healthy_threshold = 2
  }
  
  tags = {
    Name = "wsi-alb-1-tg"
  }
}

resource "aws_alb_target_group" "gyeongbuk-CICD-2-lb" {
  name     = "wsi-alb-2-tg"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = "${var.vpc}"

  health_check {
    port = 80
    path                = "/"
    timeout = 2
    interval = 5
    unhealthy_threshold = 2
    healthy_threshold = 2
  }
  tags = {
    Name = "wsi-alb-2-tg"
  }
}

resource "aws_security_group" "gyeongbuk-CICD-lb-SG" {
  name = "wsi-alb-sg"
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
    Name = "wsi-alb-sg"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}