resource "random_string" "busan_random" {
  length           = 3
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

resource "aws_s3_bucket" "busan-pipeline" {
  bucket = "wsi-artifacts-${random_string.busan_random.result}"
  force_destroy = true
}

resource "aws_codepipeline" "busan-pipeline" {
  name     = "wsi-pipeline"
  pipeline_type = "V2"
  execution_mode = "QUEUED"
  role_arn = aws_iam_role.busan-codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.busan-pipeline.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        RepositoryName = aws_codecommit_repository.busan-cicd-repo.repository_name
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
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.busan-build.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.busan-app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.busan-dg.deployment_group_name
      }
    }
  }
  depends_on = [ aws_codecommit_repository.busan-cicd-repo, aws_instance.busan-cicd-bastion]
}

data "aws_iam_policy_document" "busan-assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "busan-codepipeline_role" {
  name               = "wsi-role-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.busan-assume_role_pipeline.json
}

data "aws_iam_policy_document" "busan-codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "kms:*",
      "codecommit:*",
      "codebuild:*",
      "logs:*",
      "codedeploy:*",
      "s3:*",
      "ec2:*",
      "iam:PassRole",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "busan-codepipeline_policy" {
  name   = "busan-codepipeline_policy"
  role   = aws_iam_role.busan-codepipeline_role.id
  policy = data.aws_iam_policy_document.busan-codepipeline_policy.json
}

resource "aws_cloudwatch_event_rule" "busan-event" {
  name = "busan-ci-event"

  event_pattern = <<EOF
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${aws_codecommit_repository.busan-cicd-repo.arn}" ],
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

resource "aws_cloudwatch_event_target" "busan-event" {
  target_id = "busan-ci-event-target"
  rule = aws_cloudwatch_event_rule.busan-event.name
  arn = aws_codepipeline.busan-pipeline.arn
  role_arn = aws_iam_role.busan-ci.arn
}

resource "aws_iam_role" "busan-ci" {
  name = "busan-ci"
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

data "aws_iam_policy_document" "busan-ci" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "busan-ci" {
  name = "busan-ci-policy"
  policy = data.aws_iam_policy_document.busan-ci.json
}

resource "aws_iam_role_policy_attachment" "busan-ci" {
  policy_arn = aws_iam_policy.busan-ci.arn
  role = aws_iam_role.busan-ci.name
}