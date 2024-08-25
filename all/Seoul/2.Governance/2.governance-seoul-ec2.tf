resource "aws_instance" "seoul-test" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.public_a}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.seoul-test.id]
  associate_public_ip_address = true
#   iam_instance_profile = aws_iam_instance_profile.bastion.name
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
    Name = "wsi-test"
  }
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

## Public Security Group
resource "aws_security_group" "seoul-test" {
  name = "wsi-test-sg"
  vpc_id = "${var.vpc}"

  ingress {
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    from_port = "22"
    to_port = "22"
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
    from_port = "3306"
    to_port = "3306"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "wsi-test-sg"
  }
}