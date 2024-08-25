data "aws_caller_identity" "current" {}

# Create IAM role for CodeDeploy
data "aws_iam_policy_document" "gyeongbuk_assume_by_codedeploy" {
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

resource "aws_iam_role" "gyeongbuk_codedeploy" {
  name               = "gyeongbuk-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.gyeongbuk_assume_by_codedeploy.json
}

# Create a gyeongbuk IAM policy without cyclic dependencies
data "aws_iam_policy_document" "gyeongbuk_codedeploy_policy" {
  statement {
    sid    = "AllowgyeongbukActions"
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

resource "aws_iam_policy" "gyeongbuk_codedeploy_policy" {
  name   = "gyeongbuk-codedeploy-policy"
  policy = data.aws_iam_policy_document.gyeongbuk_codedeploy_policy.json
}

resource "aws_iam_role_policy_attachment" "gyeongbuk_codedeploy_policy_attachment" {
  role       = aws_iam_role.gyeongbuk_codedeploy.name
  policy_arn = aws_iam_policy.gyeongbuk_codedeploy_policy.arn
}

# Create CodeDeploy application
resource "aws_codedeploy_app" "wsi" {
  compute_platform = "ECS"
  name             = "wsi-cdy"
}

# Create CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "wsi" {
  app_name               = aws_codedeploy_app.wsi.name
  deployment_group_name  = "wsi-cdy-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.gyeongbuk_codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.gyeongbuk-cluster.name
    service_name = aws_ecs_service.gyeongbuk-svc.name
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
        listener_arns = [aws_lb_listener.gyeongbuk-CICD-lb.arn]
      }

      target_group {
        name = aws_alb_target_group.gyeongbuk-CICD-1-lb.name
      }

      target_group {
        name = aws_alb_target_group.gyeongbuk-CICD-2-lb.name
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.gyeongbuk_codedeploy_policy_attachment
  ]
}

# After all resources are created, update the IAM policy
data "aws_iam_policy_document" "gyeongbuk_codedeploy_policy2" {
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
      aws_ecs_service.gyeongbuk-svc.id,
      aws_codedeploy_deployment_group.wsi.arn,
      "arn:aws:codedeploy:ap-northeast-2:${data.aws_caller_identity.current.account_id}:deploymentconfig:*",
      aws_codedeploy_app.wsi.arn
    ]
  }
}

resource "aws_iam_policy" "gyeongbuk_codedeploy_policy2" {
  name   = "gyeongbuk-codedeploy-policy2"
  policy = data.aws_iam_policy_document.gyeongbuk_codedeploy_policy2.json

  depends_on = [
    aws_codedeploy_deployment_group.wsi
  ]
}

resource "aws_iam_role_policy_attachment" "gyeongbuk_codedeploy_policy_attachment2" {
  role       = aws_iam_role.gyeongbuk_codedeploy.name
  policy_arn = aws_iam_policy.gyeongbuk_codedeploy_policy2.arn

  depends_on = [
    aws_iam_policy.gyeongbuk_codedeploy_policy2
  ]
}