resource "random_string" "gyeongbuk_random" {
  length           = 4
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

resource "aws_codepipeline" "gyeongbuk-pipeline" {
  name     = "wsi-pipeline"
  role_arn = aws_iam_role.gyeongbuk-codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.gyeongbuk-pipeline.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = "${var.commit}"
        BranchName = "main"
        PollForSourceChanges = "false"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.gyeongbuk-build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeployToECS"
      input_artifacts  = ["build_output"]
      version          = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.wsi.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.wsi.deployment_group_name
        AppSpecTemplateArtifact        = "build_output"
        AppSpecTemplatePath            = "appspec.yml"
        TaskDefinitionTemplateArtifact = "build_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "build_output"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}

resource "aws_s3_bucket" "gyeongbuk-pipeline" {
  bucket_prefix = "gyeongbuk-artifacts-${random_string.gyeongbuk_random.result}"
  force_destroy = true
}

data "aws_iam_policy_document" "gyeongbuk-assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gyeongbuk-codepipeline_role" {
  name               = "wsi-role-codepipeline-gyeongbuk"
  assume_role_policy = data.aws_iam_policy_document.gyeongbuk-assume_role_pipeline.json
}

data "aws_iam_policy_document" "gyeongbuk-codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "kms:*",
      "codecommit:*",
      "codebuild:*",
      "logs:*",
      "codedeploy:*",
      "s3:*",
      "ecs:*",
      "iam:PassRole",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gyeongbuk-codepipeline_policy" {
  name   = "gyeongbuk-codepipeline_policy"
  role   = aws_iam_role.gyeongbuk-codepipeline_role.id
  policy = data.aws_iam_policy_document.gyeongbuk-codepipeline_policy.json
}

resource "aws_cloudwatch_event_rule" "gyeongbuk-event" {
  name = "gyeongbuk-ci-event"

  event_pattern = <<EOF
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${var.commit_arn}" ],
  "detail": {
     "event": [
       "referenceCreated",
       "referenceUpdated"
      ],
     "referenceType":["branch"],
     "referenceName": ["main"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "gyeongbuk-event" {
  target_id = "gyeongbuk-ci-event-target"
  rule = aws_cloudwatch_event_rule.gyeongbuk-event.name
  arn = aws_codepipeline.gyeongbuk-pipeline.arn
  role_arn = aws_iam_role.gyeongbuk-ci.arn
}

resource "aws_iam_role" "gyeongbuk-ci" {
  name = "gyeongbuk-ci-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "gyeongbuk-ci" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "gyeongbuk-ci" {
  name = "gyeongbuk-ci-policy"
  policy = data.aws_iam_policy_document.gyeongbuk-ci.json
}

resource "aws_iam_role_policy_attachment" "gyeongbuk-ci" {
  policy_arn = aws_iam_policy.gyeongbuk-ci.arn
  role = aws_iam_role.gyeongbuk-ci.name
}