resource "aws_instance" "Jeju-gvn-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.Jeju-gvn-public_a.id
  instance_type = "t3.medium"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.Jeju-gvn-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.Jeju-gvn-bastion.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y jq curl wget
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
    systemctl restart sshd
    echo 'Skill53##' | passwd --stdin ec2-user
    echo 'Skill53##' | passwd --stdin ec2-user
    sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  EOF
  tags = {
    Name = "cg-bastion"
  }
}

resource "aws_security_group" "Jeju-gvn-bastion" {
  name = "cg-EC2-SG"
  vpc_id = aws_vpc.Jeju-gvn.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
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
    Name = "cg-EC2-SG"
  }
}

## IAM
resource "aws_iam_role" "Jeju-gvn-bastion" {
  name = "cg-role-bastion"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
}

resource "aws_iam_instance_profile" "Jeju-gvn-bastion" {
  name = "cg-profile-bastion"
  role = aws_iam_role.Jeju-gvn-bastion.name
}