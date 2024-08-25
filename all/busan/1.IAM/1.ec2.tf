# EC2
resource "aws_eip" "busan-IAM-bastion" {
  instance = aws_instance.busan-IAM-bastion.id
  associate_with_private_ip = aws_instance.busan-IAM-bastion.private_ip
}

## Public EC2
resource "aws_instance" "busan-IAM-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.busan-IAM-public_b.id
  instance_type = "t3.micro"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.busan-IAM-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y curl jq
  yum install -y git
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ln -s /usr/local/bin/aws /usr/bin/
  ln -s /usr/local/bin/aws_completer /usr/bin/
  EOF
  tags = {
    Name = "wsi-project-ec2"
  }
}

## Public Security Group
resource "aws_security_group" "busan-IAM-bastion" {
  name = "busan-wsi-project-SG"
  vpc_id = aws_vpc.busan-IAM-main.id

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

    tags = {
    Name = "busan-wsi-project-SG"
  }
}