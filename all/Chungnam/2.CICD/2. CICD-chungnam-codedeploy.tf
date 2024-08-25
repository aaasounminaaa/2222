data "aws_caller_identity" "current" {}

# Create IAM role for CodeDeploy
data "aws_iam_policy_document" "chungnam_assume_by_codedeploy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chungnam_codedeploy" {
  name               = "chungnam-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.chungnam_assume_by_codedeploy.json
}

# Create a basic IAM policy without cyclic dependencies
data "aws_iam_policy_document" "basic_codedeploy_policy" {
  statement {
    sid    = "AllowBasicActions"
    effect = "Allow"
    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "s3:GetObject",
      "iam:PassRole",
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "basic_codedeploy_policy" {
  name   = "basic-codedeploy-policy"
  policy = data.aws_iam_policy_document.basic_codedeploy_policy.json
}

resource "aws_iam_role_policy_attachment" "basic_codedeploy_policy_attachment" {
  role       = aws_iam_role.chungnam_codedeploy.name
  policy_arn = aws_iam_policy.basic_codedeploy_policy.arn
}

# Create CodeDeploy application
resource "aws_codedeploy_app" "wsc2024" {
  compute_platform = "ECS"
  name             = "wsc2024-cdy"
}

# Create CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "wsc2024" {
  app_name               = aws_codedeploy_app.wsc2024.name
  deployment_group_name  = "wsc2024-cdy-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.chungnam_codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.wsc2024.name
    service_name = aws_ecs_service.wsc2024.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.wsc2024-http.arn]
      }

      target_group {
        name = aws_alb_target_group.wsc2024.name
      }

      target_group {
        name = aws_alb_target_group.wsc2024-2.name
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_codedeploy_policy_attachment
  ]
}

# After all resources are created, update the IAM policy
data "aws_iam_policy_document" "full_codedeploy_policy" {
  statement {
    sid    = "AllowLoadBalancingAndECSModifications"
    effect = "Allow"
    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "lambda:InvokeFunction",
      "cloudwatch:DescribeAlarms",
      "s3:GetObjectVersion",
      "s3:GetObject"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid    = "DeployService"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      aws_ecs_service.wsc2024.id,
      aws_codedeploy_deployment_group.wsc2024.arn,
      "arn:aws:codedeploy:us-west-1:${data.aws_caller_identity.current.account_id}:deploymentconfig:*",
      aws_codedeploy_app.wsc2024.arn
    ]
  }
}

resource "aws_iam_policy" "full_codedeploy_policy" {
  name   = "full-codedeploy-policy"
  policy = data.aws_iam_policy_document.full_codedeploy_policy.json

  depends_on = [
    aws_codedeploy_deployment_group.wsc2024
  ]
}

resource "aws_iam_role_policy_attachment" "full_codedeploy_policy_attachment" {
  role       = aws_iam_role.chungnam_codedeploy.name
  policy_arn = aws_iam_policy.full_codedeploy_policy.arn

  depends_on = [
    aws_iam_policy.full_codedeploy_policy
  ]
}