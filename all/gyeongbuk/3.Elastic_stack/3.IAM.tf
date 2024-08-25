resource "random_string" "gyeongbuk-random" {
  length  = 5
  upper   = false
  lower   = false
  numeric = true
  special = false
}

data "aws_iam_policy_document" "gyeongbuk-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gyeongbuk-role" {
  name               = "wsi-app-role"
  assume_role_policy = data.aws_iam_policy_document.gyeongbuk-assume_role.json
}

data "aws_iam_policy_document" "gyeongbuk-policy" {
  statement {
    effect    = "Allow"
    actions   = ["es:ESHttp*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gyeongbuk-policy" {
  name   = "wsi-app-policy"
  policy = data.aws_iam_policy_document.gyeongbuk-policy.json
}

resource "aws_iam_role_policy_attachment" "gyeongbuk-opensearch" {
  role       = aws_iam_role.gyeongbuk-role.name
  policy_arn = aws_iam_policy.gyeongbuk-policy.arn
}

resource "aws_iam_role_policy_attachment" "gyeongbuk-admin" {
  role       = aws_iam_role.gyeongbuk-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "gyeongbuk-app" {
  name = "wsi-profile-app-${random_string.gyeongbuk-random.result}"
  role = aws_iam_role.gyeongbuk-role.name
}