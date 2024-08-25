resource "random_string" "bucket_random" {
  length           = 4
  upper   = false
  lower   = false
  numeric  = true
  special = false
}


resource "aws_s3_bucket" "daejeon_eks" {
  bucket   = "daejeon-app-${random_string.bucket_random.result}"
}

resource "aws_s3_object" "daejeon-app" {
  bucket = aws_s3_bucket.daejeon_eks.id
  key    = "/app.py"
  source = "./Daejeon/daejeon-code/app.py"
  etag   = filemd5("./Daejeon/daejeon-code/app.py")
}

resource "aws_s3_object" "daejeon-Dockerfile" {
  bucket = aws_s3_bucket.daejeon_eks.id
  key    = "/Dockerfile"
  source = "./Daejeon/daejeon-code/Dockerfile"
  etag   = filemd5("./Daejeon/daejeon-code/Dockerfile")
}

data "aws_region" "daejeon_eks" {}
data "aws_caller_identity" "daejeon_eks" {}

resource "aws_instance" "daejeon-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.public_a}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.daejeon-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
   #!/bin/bash
    yum update -y
    yum install -y jq curl 
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
    systemctl restart sshd
    echo 'Skill53!@#' | passwd --stdin ec2-user
    echo 'Skill53!@#' | passwd --stdin root
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
    chmod +x kubectl
    mv kubectl /usr/local/bin
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    mv get_helm.sh /usr/local/bin
    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    usermod -aG docker root
    chmod 666 /var/run/docker.sock
    HOME=/home/ec2-user
    echo "export AWS_DEFAULT_REGION=${data.aws_region.daejeon_eks.name}" >> ~/.bashrc
    echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.daejeon_eks.account_id}" >> ~/.bashrc
    source ~/.bashrc
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.daejeon_eks.id}/ ~/ --recursive'
    aws ecr get-login-password --region ${data.aws_region.daejeon_eks.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.daejeon_eks.account_id}.dkr.ecr.${data.aws_region.daejeon_eks.name}.amazonaws.com
    docker build -t ${aws_ecr_repository.daejeon-ecr.repository_url}:latest ~/
    docker push ${aws_ecr_repository.daejeon-ecr.repository_url}:latest
  EOF
  tags = {
    Name = "wsi-bastion-ec2"
  }
}

## Public Security Group
resource "aws_security_group" "daejeon-bastion" {
  name = "wsi-ec2-EKS-SG"
  vpc_id = "${var.vpc}"

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

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
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
    from_port = "443"
    to_port = "443"
  }
    tags = {
    Name = "wsi-ec2-EKS-SG"
  }
}