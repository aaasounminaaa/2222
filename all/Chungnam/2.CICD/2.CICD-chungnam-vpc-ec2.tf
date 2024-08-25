data "aws_caller_identity" "caller" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_default_vpc" "chungnam-default" {
}

## Subnet 
resource "aws_default_subnet" "chungnam-default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  depends_on = [aws_default_vpc.chungnam-default]
}

resource "aws_default_subnet" "chungnam-default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  depends_on = [aws_default_vpc.chungnam-default]
}

## Route Table
resource "aws_default_route_table" "chungnam-default_rt" {
  default_route_table_id = aws_default_vpc.chungnam-default.default_route_table_id
  depends_on = [aws_default_vpc.chungnam-default]
}

## Attach Private Subnet in Route Table
data "aws_internet_gateway" "chungnam-default" {
  filter {
    name   = "attachment.vpc-id"
    values = ["${aws_default_vpc.chungnam-default.id}"]
  }
}

resource "aws_route_table_association" "chungnam-default_az1" {
  subnet_id = aws_default_subnet.chungnam-default_az1.id
  route_table_id = aws_default_route_table.chungnam-default_rt.id
  depends_on = [aws_default_vpc.chungnam-default]
}

resource "aws_route_table_association" "chungnam-default_az2" {
  subnet_id = aws_default_subnet.chungnam-default_az2.id
  route_table_id = aws_default_route_table.chungnam-default_rt.id
  depends_on = [aws_default_vpc.chungnam-default]
}

resource "aws_route" "chungnam-default" {
  route_table_id = aws_default_route_table.chungnam-default_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = data.aws_internet_gateway.chungnam-default.id
}

## Public EC2
resource "aws_instance" "chungnam-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_default_subnet.chungnam-default_az1.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.wsc2024-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y git
  yum install -y docker
  systemctl enable --now docker
  usermod -aG docker ec2-user
  usermod -aG docker root
  chmod 666 /var/run/docker.sock
  HOME=/home/ec2-user
  echo "export AWS_DEFAULT_REGION=${var.region}" >> ~/.bashrc
  echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.caller.account_id}" >> ~/.bashrc
  source ~/.bashrc
  mkdir ~/wsc2024-cci
  sudo chown ec2-user:ec2-user ~/wsc2024-cci
  su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.chungnam-app.id}/ ~/wsc2024-cci --recursive'
  su - ec2-user -c 'git config --global credential.helper "!aws codecommit credential-helper $@"'
  su - ec2-user -c 'git config --global credential.UseHttpPath true'
  su - ec2-user -c 'cd ~/wsc2024-cci && git init && git add .'
  su - ec2-user -c 'cd ~/wsc2024-cci && git commit -m "first commit"'
  su - ec2-user -c 'cd ~/wsc2024-cci && git remote add origin ${aws_codecommit_repository.chungnam-test.clone_url_http}'
  su - ec2-user -c 'cd ~/wsc2024-cci && git push origin master'
  aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.caller.account_id}.dkr.ecr.${var.region}.amazonaws.com
  docker build -f ~/wsc2024-cci/docker_build -t ${aws_ecr_repository.wsc2024-repo.repository_url}:latest ~/wsc2024-cci
  docker push ${aws_ecr_repository.wsc2024-repo.repository_url}:latest
  EOF
  tags = {
    Name = "wsc2024-bastion-ec2"
  }
  depends_on = [ aws_codecommit_repository.chungnam-test,aws_ecr_repository.wsc2024-repo ]
}

## Public Security Group
resource "aws_security_group" "wsc2024-bastion" {
  name = "wsc2024-bastion-SG"
  vpc_id = aws_default_vpc.chungnam-default.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }
 
  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }
  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }
    tags = {
    Name = "wsc2024-bastion-SG"
  }
}

resource "aws_iam_role" "code_build_role" {
  name = "codebuild-wsc2024-cbd-service-role"

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
    Name = "codebuild-wsc2024-cbd-service-role"
  }
}


resource "aws_iam_policy" "code_build_policy" {
  name = "codebuild-wsc2024-cbd-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Resource = [
          "arn:aws:logs:us-west-1:${data.aws_caller_identity.caller.account_id}:log-group:/aws/codebuild/wsc2024-cbd",
          "arn:aws:logs:us-west-1:${data.aws_caller_identity.caller.account_id}:log-group:/aws/codebuild/wsc2024-cbd:*"
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
          "arn:aws:s3:::codepipeline-us-west-1-*"
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
          "arn:aws:codecommit:us-west-1:${data.aws_caller_identity.caller.account_id}:wsc2024-cci"
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
          "arn:aws:codebuild:us-west-1:${data.aws_caller_identity.caller.account_id}:report-group/wsc2024-cbd-*"
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