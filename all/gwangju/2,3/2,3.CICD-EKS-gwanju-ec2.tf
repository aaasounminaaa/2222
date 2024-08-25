## CICD bastion ##
data "aws_region" "gwangju-current" {}
data "aws_caller_identity" "gwangju" {}

resource "aws_s3_bucket" "gwangju-object" {
  bucket = "gwangju-object-123"
  force_destroy = true
}

resource "aws_s3_object" "gwangju-buildspec" {
  bucket = aws_s3_bucket.gwangju-object.id
  key    = "/buildspec.yaml"
  source = "./gwangju/src/buildspec.yaml"
  etag   = filemd5("./gwangju/src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "gwangju-Dockerfile" {
  bucket = aws_s3_bucket.gwangju-object.id
  key    = "/Dockerfile"
  source = "./gwangju/src/Dockerfile"
  etag   = filemd5("./gwangju/src/Dockerfile")
}

resource "aws_s3_object" "gwangju-deployment" {
  bucket = aws_s3_bucket.gwangju-object.id
  key    = "/deployment.yaml"
  source = "./gwangju/src/deployment.yaml"
  etag   = filemd5("./gwangju/src/deployment.yaml")
}

resource "aws_s3_object" "gwangju-kustomization" {
  bucket = aws_s3_bucket.gwangju-object.id
  key    = "/kustomization.yaml"
  source = "./gwangju/src/kustomization.yaml"
  etag   = filemd5("./gwangju/src/kustomization.yaml")
}

resource "aws_s3_object" "gwangju-main" {
  bucket = aws_s3_bucket.gwangju-object.id
  key    = "/main.py"
  source = "./gwangju/src/main.py"
  etag   = filemd5("./gwangju/src/main.py")
}

resource "aws_s3_object" "gwangju-requirements" {
  bucket = aws_s3_bucket.gwangju-object.id
  key    = "/requirements.txt"
  source = "./gwangju/src/requirements.txt"
  etag   = filemd5("./gwangju/src/requirements.txt")
}

resource "aws_instance" "CICD-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.gwangju-public_a.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.EKS-bastion.id]
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
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  mv /tmp/eksctl /usr/bin
  curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  mv ./kubectl /usr/bin/
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  sudo chmod 700 get_helm.sh
  ./get_helm.sh
  sudo mv ./get_helm.sh /usr/local/bin
  yum install -y docker
  systemctl enable --now docker
  usermod -aG docker ec2-user
  usermod -aG docker root
  chmod 666 /var/run/docker.sock
  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
  rm -rf argocd-linux-amd64
  yum install -y git
  HOME=/home/ec2-user
  echo "export AWS_DEFAULT_REGION=${data.aws_region.gwangju-current.name}" >> ~/.bashrc
  echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.gwangju.account_id}" >> ~/.bashrc
  source ~/.bashrc
  mkdir ~/gwangju-application-repo
  sudo chown ec2-user:ec2-user ~/gwangju-application-repo
  su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.gwangju-object.id}/ ~/gwangju-application-repo --recursive'
  su - ec2-user -c 'git config --global credential.helper "!aws codecommit credential-helper $@"'
  su - ec2-user -c 'git config --global credential.UseHttpPath true'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git init && git add .'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git commit -m "first commit"'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git branch main'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git checkout main'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git branch -d master'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git remote add origin ${var.code_commmit}'
  su - ec2-user -c 'cd ~/gwangju-application-repo && git push origin main'
  aws s3 rm s3://${aws_s3_bucket.gwangju-object.id} --recursive
  aws s3 rb s3://${aws_s3_bucket.gwangju-object.id} --force
  EOF
  tags = {
    Name = "gwangju-bastion-ec2"
  }
}

## EKS EC2 SG ##
resource "aws_security_group" "EKS-bastion" {
  name = "gwangju-ec2-SG"
  vpc_id = aws_vpc.gwangju-main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
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
    Name = "gwangju-ec2-SG"
  }
}