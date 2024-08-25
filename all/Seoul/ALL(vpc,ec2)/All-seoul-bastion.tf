## Public EC2
resource "aws_instance" "seoul-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.seoul-public_a.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.seoul-bastion.id]
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
  EOF
  tags = {
    Name = "seoul-bastion-ec2"
  }
}

## Public Security Group
resource "aws_security_group" "seoul-bastion" {
  name = "seoul-bastion-SG"
  vpc_id = aws_vpc.seoul-main.id

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
    Name = "seoul-bastion-SG"
  }
}