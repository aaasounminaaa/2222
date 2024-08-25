data "aws_region" "gyeongbuk-current" {}
data "aws_caller_identity" "gyeongbuk-current" {}

resource "random_string" "gyeongbuk-random" {
  length  = 4
  lower   = true
  upper   = false
  special = false
}

resource "aws_s3_bucket" "gyeongbuk-object" {
  bucket        = "gyeongbuk-object-${random_string.gyeongbuk-random.result}"
  force_destroy = true
}


resource "aws_s3_object" "gyeongbuk-buildspec" {
  bucket = aws_s3_bucket.gyeongbuk-object.id
  key    = "/buildspec.yaml"
  source = "./gyeongbuk/src/buildspec.yaml"
  etag   = filemd5("./gyeongbuk/src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "gyeongbuk-Dockerfile" {
  bucket = aws_s3_bucket.gyeongbuk-object.id
  key    = "/Dockerfile"
  source = "./gyeongbuk/src/Dockerfile"
  etag   = filemd5("./gyeongbuk/src/Dockerfile")
}

resource "aws_s3_object" "gyeongbuk-html" {
  bucket = aws_s3_bucket.gyeongbuk-object.id
  key    = "/index.html"
  source = "./gyeongbuk/src/index.html"
  etag   = filemd5("./gyeongbuk/src/index.html")
}

resource "aws_s3_object" "gyeongbuk-appspec" {
  bucket = aws_s3_bucket.gyeongbuk-object.id
  key    = "/appspec.yml"
  source = "./gyeongbuk/src/appspec.yml"
  etag   = filemd5("./gyeongbuk/src/appspec.yml")
}

resource "aws_s3_object" "gyeongbuk-taskdef" {
  bucket = aws_s3_bucket.gyeongbuk-object.id
  key    = "/taskdef.json"
  source = "./gyeongbuk/src/taskdef.json"
  etag   = filemd5("./gyeongbuk/src/taskdef.json")
}



## Public EC2
resource "aws_instance" "gyeongbuk-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.gyeongbuk-public_a.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.gyeongbuk-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y jq curl wget
    yum install -y git
    yum install -y dos2unix
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    usermod -aG docker root
    chmod 666 /var/run/docker.sock
    sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
    systemctl restart sshd
    echo 'Skill53##' | passwd --stdin ec2-user
    echo 'Skill53##' | passwd --stdin root
    HOME=/home/ec2-user
    echo "export AWS_DEFAULT_REGION=${data.aws_region.gyeongbuk-current.name}" >> ~/.bashrc
    echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.gyeongbuk-current.account_id}" >> ~/.bashrc
    source ~/.bashrc
    mkdir ~/wsi-commit
    sudo chown ec2-user:ec2-user ~/wsi-commit
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.gyeongbuk-object.id}/ ~/wsi-commit --recursive'
    su - ec2-user -c 'git config --global credential.helper "!aws codecommit credential-helper $@"'
    su - ec2-user -c 'git config --global credential.UseHttpPath true'
    su - ec2-user -c 'cd ~/wsi-commit && git init && git add .'
    su - ec2-user -c 'cd ~/wsi-commit && git commit -m "first commit"'
    su - ec2-user -c 'cd ~/wsi-commit && git branch main'
    su - ec2-user -c 'cd ~/wsi-commit && git checkout main'
    su - ec2-user -c 'cd ~/wsi-commit && git branch -d master'
    su - ec2-user -c 'cd ~/wsi-commit && git remote add origin ${aws_codecommit_repository.gyeongbuk-commit.clone_url_http}'
    su - ec2-user -c 'cd ~/wsi-commit && git push origin main'
    aws s3 rm s3://${aws_s3_bucket.gyeongbuk-object.id} --recursive
    aws s3 rb s3://${aws_s3_bucket.gyeongbuk-object.id} --force
  EOF
  tags = {
    Name = "wsi-bastion"
  }
  depends_on = [ aws_codecommit_repository.gyeongbuk-commit ]
}

resource "aws_security_group" "gyeongbuk-bastion" {
  name = "wsi-bastion-sg"
  vpc_id = aws_vpc.gyeongbuk-main.id

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
    from_port = "5000"
    to_port = "5000"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }
  tags = {
    Name = "wsi-bastion-sg"
  }
}