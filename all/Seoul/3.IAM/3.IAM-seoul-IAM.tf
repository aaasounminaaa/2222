resource "aws_iam_user" "seoul-tester" {
  name = "tester"
  tags = {
    Name = "tester"
  }
}

resource "aws_iam_user_policy_attachment" "seoul-test-attach" {
  user       = aws_iam_user.seoul-tester.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy" "seoul-tester-policy" {
  name        = "mfaBucketDeleteControl"
  description = "A mfaBucketDeleteControl policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor1",
            "Effect": "Deny",
            "Action": [
                "s3:DeleteBucket"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
  })
}

resource "aws_iam_group_policy" "seoul-regionAccessControl" {
  name  = "regionAccessControl"
  group = aws_iam_group.seoul-user_group_kr.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": "ap-northeast-2"
                }
            }
        }
    ]
  })
}

resource "aws_iam_group" "seoul-user_group_kr" {
  name = "user_group_kr"
}

resource "aws_iam_group_membership" "seoul-user_group_kr" {
  name = "user_group_kr-membership"

  users = [
    aws_iam_user.seoul-tester.name
  ]

  group = aws_iam_group.seoul-user_group_kr.name
}

resource "aws_iam_user_policy_attachment" "seoul-tester-attach" {
  user       = aws_iam_user.seoul-tester.name
  policy_arn = aws_iam_policy.seoul-tester-policy.arn
}