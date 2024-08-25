## Public EC2
resource "aws_instance" "governace-chungnam-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.default_az1}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.governace-chungnam-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y dos2unix
  EOF
  tags = {
    Name = "wsc2024-governace-bastion-ec2"
  }
}

resource "aws_security_group" "governace-chungnam-bastion" {
  name = "wsc2024-governace-bastion-sg"
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
    from_port = "22"
    to_port = "22"
  }

    tags = {
    Name = "wsc2024-governace-bastion-sg"
  }
}