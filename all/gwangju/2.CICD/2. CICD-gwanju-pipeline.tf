variable "file_name" {
  type        = string
  default     = "imagedefinitions.json"
}

resource "aws_codepipeline" "gwangju-pipeline" {
  name     = "gwangju-pipeline"
  role_arn = aws_iam_role.gwangju-codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.gwangju-pipeline.bucket
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
        RepositoryName = aws_codecommit_repository.gwangju-test.repository_name
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
        ProjectName = aws_codebuild_project.gwangju-build.name
      }
    }
  }
}

resource "aws_s3_bucket" "gwangju-pipeline" {
  bucket_prefix = "wsi-gwangju-artifacts"
  force_destroy = true
}

data "aws_iam_policy_document" "gwangju-assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gwangju-codepipeline_role" {
  name               = "wsi-role-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.gwangju-assume_role_pipeline.json
}

data "aws_iam_policy_document" "gwangju-codepipeline_policy" {
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

resource "aws_iam_role_policy" "gwangju-codepipeline_policy" {
  name   = "gwangju-codepipeline_policy"
  role   = aws_iam_role.gwangju-codepipeline_role.id
  policy = data.aws_iam_policy_document.gwangju-codepipeline_policy.json
}

resource "aws_cloudwatch_event_rule" "gwangju-event" {
  name = "wsi-ci-event"

  event_pattern = <<EOF
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${aws_codecommit_repository.gwangju-test.arn}" ],
  "detail": {
     "event": [
       "referenceCreated",
       "referenceUpdated"
      ],
     "referenceType":["branch"],
     "referenceName": ["master"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "gwangju-event" {
  target_id = "wsi-ci-event-target"
  rule = aws_cloudwatch_event_rule.gwangju-event.name
  arn = aws_codepipeline.gwangju-pipeline.arn
  role_arn = aws_iam_role.gwangju-ci.arn
}

resource "aws_iam_role" "gwangju-ci" {
  name = "wsi-ci"
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

data "aws_iam_policy_document" "gwangju-ci" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "gwangju-ci" {
  name = "wsi-ci-policy"
  policy = data.aws_iam_policy_document.gwangju-ci.json
}

resource "aws_iam_role_policy_attachment" "gwangju-ci" {
  policy_arn = aws_iam_policy.gwangju-ci.arn
  role = aws_iam_role.gwangju-ci.name
}