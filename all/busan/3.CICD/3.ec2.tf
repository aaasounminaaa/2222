resource "aws_instance" "busan-cicd-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.default_az1}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.busan-cicd-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y curl jq
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ln -s /usr/local/bin/aws /usr/bin/
  ln -s /usr/local/bin/aws_completer /usr/bin/
  yum install -y git
  yum install -y docker
  systemctl enable --now docker
  usermod -aG docker ec2-user
  usermod -aG docker root
  chmod 666 /var/run/docker.sock
  HOME=/home/ec2-user
  echo "export AWS_DEFAULT_REGION=${var.region}" >> ~/.bashrc
  source ~/.bashrc
  mkdir ~/wsi-repo
  sudo chown ec2-user:ec2-user ~/wsi-repo
  su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.busan-app.id}/ ~/wsi-repo --recursive'
  su - ec2-user -c 'git config --global credential.helper "!aws codecommit credential-helper $@"'
  su - ec2-user -c 'git config --global credential.UseHttpPath true'
  su - ec2-user -c 'cd ~/wsi-repo && git init && git add .'
  su - ec2-user -c 'cd ~/wsi-repo && git commit -m "first commit"'
  su - ec2-user -c 'cd ~/wsi-repo && git branch main'
  su - ec2-user -c 'cd ~/wsi-repo && git checkout main'
  su - ec2-user -c 'cd ~/wsi-repo && git branch -d master'
  su - ec2-user -c 'cd ~/wsi-repo && git remote add origin ${aws_codecommit_repository.busan-cicd-repo.clone_url_http}'
  su - ec2-user -c 'cd ~/wsi-repo && git push origin main'
  aws s3 rm s3://${aws_s3_bucket.busan-app.id} --recursive
  aws s3 rb s3://${aws_s3_bucket.busan-app.id} --force
  EOF
  tags = {
    Name = "wsi-bastion"
  }
}

## Public Security Group
resource "aws_security_group" "busan-cicd-bastion" {
  name = "wsi-bastion-SG"
  vpc_id = "${var.default_vpc}"

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
    Name = "wsi-bastion-SG"
  }
}

resource "aws_instance" "busan-cicd-server" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.default_az1}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.busan-cicd-server.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y curl jq
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
  yum install -y ruby
  yum install -y wget
  wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
  chmod +x ./install
  ./install auto
  systemctl enable --now codedeploy-agent.service
  EOF
  tags = {
    Name = "wsi-server"
  }
}

resource "aws_security_group" "busan-cicd-server" {
  name = "wsi-server-SG"
  vpc_id = "${var.default_vpc}"

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
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

    tags = {
    Name = "wsi-server-SG"
  }
}