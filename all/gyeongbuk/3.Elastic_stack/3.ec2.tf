resource "aws_instance" "gyeongbuk-app" {
  ami = "${var.aws_ami}"
  subnet_id = "${var.private_a}"
  instance_type = "t3.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.gyeongbuk-app.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.gyeongbuk-app.name
  user_data = "${file("./gyeongbuk/3.Elastic_stack/src/userdata.sh")}"
  tags = {
    Name = "wsi-app"
  }
  depends_on = [ aws_opensearch_domain.gyeongbuk-opensearch ]
}

resource "aws_security_group" "gyeongbuk-app" {
  name = "wsi-app-sg"
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
    from_port = "5000"
    to_port = "5000"
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
    Name = "wsi-app-sg"
  }
}