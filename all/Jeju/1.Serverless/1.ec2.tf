resource "aws_instance" "Jeju-serverless-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.Jeju-serverless-public_a.id
  instance_type = "t3.medium"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.Jeju-serverless-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y jq curl wget git
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
  EOF
  
  tags = {
    Name = "serverless-bastion"
  }
}

resource "aws_security_group" "Jeju-serverless-bastion" {
  name = "serverless-bastion-sg"
  vpc_id = aws_vpc.Jeju-serverless.id

  ingress {
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
    Name = "serverless-bastion-sg"
  }
}