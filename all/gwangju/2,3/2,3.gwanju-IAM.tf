## CICD IAM ##
data "aws_caller_identity" "gwangju-current" {}

resource "random_string" "gwangju_random" {
  length           = 4
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

resource "aws_iam_role" "code_build_role" {
  name = "codebuild-gwangju-build-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "codebuild-gwangju-build-service-role"
  }
}


resource "aws_iam_policy" "code_build_policy" {
  name = "codebuild-gwangju-build-service-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Resource = [
          "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.gwangju-current.account_id}:log-group:*",
          "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.gwangju-current.account_id}:log-group:*:*"
        ],
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::codepipeline-ap-northeast-2-*"
        ],
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        Effect = "Allow",
        Resource = [
          "arn:aws:codecommit:ap-northeast-2:${data.aws_caller_identity.gwangju-current.account_id}:gwangju-application-repo"
        ],
        Action = [
          "codecommit:GitPull"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource = [
          "arn:aws:codebuild:ap-northeast-2:${data.aws_caller_identity.gwangju-current.account_id}:report-group/gwangju-build-*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:*",
          "cloudtrail:LookupEvents"
        ],
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "iam:CreateServiceLinkedRole"
        ],
        Resource = [
          "*"
        ],
        Condition = {
          "ForAnyValue:StringEquals" = {
            "iam:AWSServiceName" = "replication.ecr.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "code_build_role_policy_attachment" {
  role       = aws_iam_role.code_build_role.name
  policy_arn = aws_iam_policy.code_build_policy.arn
}