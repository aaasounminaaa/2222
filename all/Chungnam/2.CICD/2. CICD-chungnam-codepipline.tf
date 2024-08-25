variable "file_name" {
  type        = string
  default     = "imagedefinitions.json"
}

resource "aws_codepipeline" "chungnam-pipeline" {
  name     = "wsc2024-pipeline"
  role_arn = aws_iam_role.chungnam-codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.chungnam-pipeline.bucket
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
      namespace = "NewCommit"
      configuration = {
        RepositoryName = aws_codecommit_repository.chungnam-test.repository_name
        BranchName = "master"
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
        ProjectName = aws_codebuild_project.Chungnam-build.name
      }
    }
  }
  stage {
    name = "approval"
    action {
        name            = "approval"
        category         = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"
    configuration = {
      CustomData = "new CommitId : #{NewCommit.CommitId}"
      ExternalEntityLink = "https://us-west-1.console.aws.amazon.com/codesuite/codecommit/repositories/wsc2024-cci/commit/#{NewCommit.CommitId}?region=us-west-1"
        }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.wsc2024.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.wsc2024.deployment_group_name
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath            = "appspec.yml"
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}

resource "random_string" "wsc2024_random" {
  length           = 3
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

resource "aws_s3_bucket" "chungnam-pipeline" {
  bucket = "wsc2024-artifacts-${random_string.wsc2024_random.result}"
  force_destroy = true
}

resource "aws_s3_bucket" "chungnam-app" {
  bucket = "wsc2024-app-${random_string.wsc2024_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "appspec" {
  bucket = aws_s3_bucket.chungnam-app.id
  key    = "/appspec.yml"
  source = "./Chungnam/src/appspec.yml"
  etag   = filemd5("./Chungnam/src/appspec.yml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "buildspec" {
  bucket = aws_s3_bucket.chungnam-app.id
  key    = "/buildspec.yaml"
  source = "./Chungnam/src/buildspec.yaml"
  etag   = filemd5("./Chungnam/src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.chungnam-app.id
  key    = "/main.py"
  source = "./Chungnam/src/main.py"
  etag   = filemd5("./Chungnam/src/main.py")
  # content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "task" {
  bucket = aws_s3_bucket.chungnam-app.id
  key    = "/taskdef.json"
  source = "./Chungnam/src/taskdef.json"
  etag   = filemd5("./Chungnam/src/taskdef.json")
  content_type = "application/json"
}

resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.chungnam-app.id
  key    = "/requirements.txt"
  source = "./Chungnam/src/requirements.txt"
  etag   = filemd5("./Chungnam/src/requirements.txt")
  # content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "html" {
  bucket = aws_s3_bucket.chungnam-app.id
  key    = "/templates/index.html"
  source = "./Chungnam/src/templates/index.html"
  etag   = filemd5("./Chungnam/src/templates/index.html")
  # content_type = "application/vnd.yaml"
}

data "aws_iam_policy_document" "chungnam-assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "chungnam-codepipeline_role" {
  name               = "chungnam-role-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.chungnam-assume_role_pipeline.json
}

data "aws_iam_policy_document" "chungnam-codepipeline_policy" {
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

resource "aws_iam_role_policy" "chungnam-codepipeline_policy" {
  name   = "chungnam-codepipeline_policy"
  role   = aws_iam_role.chungnam-codepipeline_role.id
  policy = data.aws_iam_policy_document.chungnam-codepipeline_policy.json
}

resource "aws_cloudwatch_event_rule" "chungnam-event" {
  name = "chungnam-ci-event"

  event_pattern = <<EOF
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${aws_codecommit_repository.chungnam-test.arn}" ],
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

resource "aws_cloudwatch_event_target" "chungnam-event" {
  target_id = "chungnam-ci-event-target"
  rule = aws_cloudwatch_event_rule.chungnam-event.name
  arn = aws_codepipeline.chungnam-pipeline.arn
  role_arn = aws_iam_role.chungnam-ci.arn
}

resource "aws_iam_role" "chungnam-ci" {
  name = "chungnam-ci-role"
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

data "aws_iam_policy_document" "chungnam-ci" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "chungnam-ci" {
  name = "chungnam-ci-policy"
  policy = data.aws_iam_policy_document.chungnam-ci.json
}

resource "aws_iam_role_policy_attachment" "chungnam-ci" {
  policy_arn = aws_iam_policy.chungnam-ci.arn
  role = aws_iam_role.chungnam-ci.name
}