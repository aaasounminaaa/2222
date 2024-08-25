resource "aws_ecs_task_definition" "wsc2024" {
  family                   = "wsc2024-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.chungnam-app_task_role.arn
  # task_role_arn            = aws_iam_role.chungnam-app_task_role.arn
  container_definitions = <<DEFINITION
[
  {
    "image": "${data.aws_caller_identity.caller.account_id}.dkr.ecr.us-west-1.amazonaws.com/wsc2024-repo:latest",
    "cpu": 512,
    "memory": 1024,
    "name": "wsc2024-container",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "healthCheck": {
      "command": [
        "CMD-SHELL",
        "curl -fLs http://localhost:8080/healthcheck || exit 1"
      ],
      "interval": 5,
      "timeout": 2,
      "retries": 1,
      "startPeriod": 0
    },
    "essential": true
  }
]
DEFINITION
  depends_on = [aws_instance.chungnam-bastion]
}

resource "aws_iam_role" "chungnam-app_task_role" {
  name = "chungnam-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "ecs-tasks.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ECS_task_execution" {
  role       = aws_iam_role.chungnam-app_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}