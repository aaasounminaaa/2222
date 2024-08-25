resource "aws_instance" "J-company-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.J-company-public_a.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.J-company-bastion.id]
  associate_public_ip_address = false
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  echo "Skill53##" | passwd --stdin ec2-user
  sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
  yum install -y curl jq
  sudo yum install -y ec2-instance-connect
  EOF
  tags = {
    Name = "J-company-bastion"
  }
}

## Public Security Group
resource "aws_security_group" "J-company-bastion" {
  name = "J-company-bastion-SG"
  vpc_id = aws_vpc.J-company.id

  ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.J-company-connect-sg.id]
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
    Name = "J-company-bastion-SG"
  }
  depends_on = [ aws_security_group.J-company-connect-sg ]
}