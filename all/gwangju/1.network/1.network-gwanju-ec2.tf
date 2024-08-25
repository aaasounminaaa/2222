## Egress-bastion ##
resource "aws_instance" "egress-bastion" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.egress-private_b.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.egress-bastion.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.egress-bastion.name
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable --now amazon-ssm-agent
  EOF
  tags = {
    Name = "gwangju-EgressVPC-Instance"
  }
}

## Egress-bastion-SG
resource "aws_security_group" "egress-bastion" {
  name = "gwangju-EgressVPC-Instance-sg"
  vpc_id = aws_vpc.egress-main.id

  ingress {
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = -1
    to_port = -1
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-EgressVPC-Instance-sg"
  }
}


## gwanju-vpc1-ec2 ##
resource "aws_instance" "bastion-1" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.private_a-1.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.bastion-1.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.ssm-bastion.name
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl restart amazon-ssm-agent.service
  systemctl enable --now amazon-ssm-agent
  EOF
  tags = {
    Name = "gwangju-VPC1-Instance"
  }
  depends_on = [ aws_vpc_endpoint.ec2-1,aws_vpc_endpoint.ec2-message-1,aws_vpc_endpoint.ssm-1,aws_vpc_endpoint.ssm-message-1,aws_vpc_endpoint_subnet_association.sub-a-1,aws_vpc_endpoint_subnet_association.sub-b-1,aws_vpc_endpoint_subnet_association.sub-a-message-1,aws_vpc_endpoint_subnet_association.sub-b-message-1,aws_vpc_endpoint_subnet_association.sub-a-ec2-1,aws_vpc_endpoint_subnet_association.sub-b-ec2-1,aws_vpc_endpoint_subnet_association.sub-a-ec2-message-1,aws_vpc_endpoint_subnet_association.sub-b-ec2-message-1 ]
}

## gwanju-vpc1-ec2-SG ##
resource "aws_security_group" "bastion-1" {
  name = "gwangju-VPC1-Instance-sg"
  vpc_id = aws_vpc.main-1.id

  ingress {
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = -1
    to_port = -1
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-VPC1-Instance-sg"
  }
}

resource "aws_security_group" "vpc-1-endpiont" {
  name = "gwangju-vpc1-endpiont-sg"
  vpc_id = aws_vpc.main-1.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port = 443
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-vpc1-endpiont-sg"
  }
}

## gwanju-vpc2-ec2 ##
resource "aws_instance" "bastion-2" {
  ami = "${var.aws_ami}"
  subnet_id = aws_subnet.private_a-2.id
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.bastion-2.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.ssm-bastion.name
  user_data = <<-EOF
  #!/bin/bash
  echo 'Skill53##' | passwd --stdin ec2-user
  yum update -y
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl restart amazon-ssm-agent.service
  systemctl enable --now amazon-ssm-agent
  EOF
  tags = {
    Name = "gwangju-VPC2-Instance"
  }
  depends_on = [ aws_route_table.private_a-2,aws_route.vpc2-egress-pri-a-tgw,aws_vpc_endpoint.ec2-2,aws_vpc_endpoint.ec2-message-2,aws_vpc_endpoint.ssm-2,aws_vpc_endpoint.ssm-message-2,aws_vpc_endpoint_subnet_association.sub-a-2,aws_vpc_endpoint_subnet_association.sub-b-2,aws_vpc_endpoint_subnet_association.sub-a-message-2,aws_vpc_endpoint_subnet_association.sub-b-message-2,aws_vpc_endpoint_subnet_association.sub-a-ec2-2,aws_vpc_endpoint_subnet_association.sub-b-ec2-2,aws_vpc_endpoint_subnet_association.sub-a-ec2-message-2,aws_vpc_endpoint_subnet_association.sub-b-ec2-message-2 ]
}

## gwanju-vpc2-ec2-SG ##
resource "aws_security_group" "bastion-2" {
  name = "gwangju-VPC2-Instance-sg"
  vpc_id = aws_vpc.main-2.id

  ingress {
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = -1
    to_port = -1
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port = 443
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-VPC2-Instance-sg"
  }
}

resource "aws_security_group" "vpc-2-endpiont" {
  name = "gwangju-vpc2-endpiont-sg"
  vpc_id = aws_vpc.main-2.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port = 443
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-vpc2-endpiont-sg"
  }
}