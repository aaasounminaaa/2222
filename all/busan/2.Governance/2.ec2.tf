resource "aws_instance" "busan-gvn-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.default_az1}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.busan-gvn-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = "${var.admin_profile_name}"
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y jq curl vim
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
    echo "Port 2220" >> /etc/ssh/sshd_config
    systemctl restart sshd
    echo 'Skill53##' | passwd --stdin ec2-user
    echo 'Skill53##' | passwd --stdin root
  EOF
  tags = {
    Name = "wsi-bastion-ec2"
  }
}

resource "aws_security_group" "busan-gvn-bastion" {
  name = "wsi-EC2-SG"
  vpc_id = "${var.default_vpc}"

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "2220"
    to_port = "2220"
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
    Name = "wsi-EC2-SG"
  }
}