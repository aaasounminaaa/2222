resource "aws_iam_user" "wsi-project-user1" {
  name = "wsi-project-user1"
  tags = {
    Name = "wsi-project-user1"
  }
}

# resource "aws_iam_access_key" "lb" {
#   user = aws_iam_user.Admin.name
# }

data "aws_iam_policy_document" "user1-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateVolume"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:network-interface/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/wsi-project"
      values   = ["developer"]
    }
  }

  statement {
    sid    = "VisualEditor1"
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:network-interface/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = [
        "RunInstances",
        "CreateVolume"
      ]
    }
  }

  statement {
    effect    = "Allow"
    actions   = [
      "ec2:Describe*",
      "ec2:CreateSecurityGroup",
			"ec2:ModifyNetworkInterfaceAttribute",
			"ec2:DeleteSecurityGroup",
			"ec2:AuthorizeSecurityGroupIngress"
      ]
    resources = ["*"]
  }

  statement {
    sid    = "VisualEditor3"
    effect = "Allow"
    actions = [
      "ec2:RunInstances"
    ]
    resources = [
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:key-pair/*",
      "arn:aws:ec2:*::snapshot/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*:*:volume/*"
    ]
  }
}

resource "aws_iam_policy" "wsi-project-1-policy" {
  name        = "wsi-project-1-policy"
  policy      = data.aws_iam_policy_document.user1-policy.json
}

resource "aws_iam_user_login_profile" "wsi-project-1-console_access_profile" {
  user                  = aws_iam_user.wsi-project-user1.name  # Replace with the name of your existing IAM user
  password_reset_required = true
}

resource "aws_iam_user_policy_attachment" "user1-Admin-attach" {
  user       = aws_iam_user.wsi-project-user1.name
  policy_arn = aws_iam_policy.wsi-project-1-policy.arn
}

#################################################################

resource "aws_iam_user" "wsi-project-user2" {
  name = "wsi-project-user2"
  tags = {
    Name = "wsi-project-user2"
  }
}

resource "aws_iam_user_login_profile" "wsi-project-user2-console_access_profile" {
  user                  = aws_iam_user.wsi-project-user2.name
  password_reset_required = true
}

data "aws_iam_policy_document" "user2-policy" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances","ec2:DescribeImages","ec2:DescribeTags","ec2:DescribeSnapshots","ec2:DescribeVolumes"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:TerminateInstances"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/wsi-project"
      values   = ["developer"]
    }
  }

  statement {
    effect    = "Deny"
    actions   = ["ec2:TerminateInstances"]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "ec2:ResourceTag/wsi-project"
      values   = ["developer"]
    }
  }
}


resource "aws_iam_policy" "wsi-project-2-policy" {
  name        = "wsi-project-2-policy"
  policy      = data.aws_iam_policy_document.user2-policy.json
}

resource "aws_iam_user_policy_attachment" "user2-attach" {
  user       = aws_iam_user.wsi-project-user2.name
  policy_arn = aws_iam_policy.wsi-project-2-policy.arn
}

output "user1_PASSWORD" {
    value = aws_iam_user_login_profile.wsi-project-1-console_access_profile.password
}

output "user2_PASSWORD" {
    value = aws_iam_user_login_profile.wsi-project-user2-console_access_profile.password
}

# output "Employee_ACCESS_KEY" {
#     value = aws_iam_access_key.lb_Employee.id
# }

# output "Employee_secret_key" {
#     value = aws_iam_access_key.lb_Employee.secret
#     sensitive = true
# }