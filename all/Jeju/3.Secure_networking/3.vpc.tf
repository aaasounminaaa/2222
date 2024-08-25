resource "aws_vpc" "J-company" {
  cidr_block = "210.89.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "J-company-vpc"
  }
}


## Route Table
resource "aws_route_table" "J-company-public" {
  vpc_id = aws_vpc.J-company.id

  tags = {
    Name = "J-company-priv-a-rt"
  }
}

## Public Subnet
resource "aws_subnet" "J-company-public_a" {
  vpc_id = aws_vpc.J-company.id
  cidr_block = "210.89.3.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "J-company-priv-sub-a"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "J-company-public_a" {
  subnet_id = aws_subnet.J-company-public_a.id
  route_table_id = aws_route_table.J-company-public.id
}

## Route Table
resource "aws_route_table" "J-company-private_a" {
  vpc_id = aws_vpc.J-company.id

  tags = {
    Name = "J-company-priv-b-rt"
  }
}

resource "aws_subnet" "J-company-private_a" {
  vpc_id = aws_vpc.J-company.id
  cidr_block = "210.89.0.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "J-company-priv-sub-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "J-company-private_a" {
  subnet_id = aws_subnet.J-company-private_a.id
  route_table_id = aws_route_table.J-company-private_a.id
}

resource "aws_security_group" "J-company-connect-sg" {
  name = "J-company-ep-SG"
  vpc_id = aws_vpc.J-company.id

  egress {
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
    tags = {
    Name = "J-company-ep-SG"
  }
}

resource "aws_ec2_instance_connect_endpoint" "J-company-connect" {
  subnet_id = aws_subnet.J-company-private_a.id
  security_group_ids = [aws_security_group.J-company-connect-sg.id]
  tags = {
    Name = "J-company-endpoint-ec2"
  }
}



resource "aws_vpc_endpoint" "J-company-s3" {
  vpc_id            = aws_vpc.J-company.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "J-company-s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "J-company-s3_private_a" {
  route_table_id  = aws_route_table.J-company-private_a.id
  vpc_endpoint_id = aws_vpc_endpoint.J-company-s3.id
}

resource "aws_vpc_endpoint_route_table_association" "J-company-s3_public_b" {
  route_table_id  = aws_route_table.J-company-public.id
  vpc_endpoint_id = aws_vpc_endpoint.J-company-s3.id
}

resource "aws_vpc_endpoint_policy" "J-company-s3" {
  vpc_endpoint_id = aws_vpc_endpoint.J-company-s3.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "*",
        "Resource" : "*"
      },
      {
        "Sid" : "DenySpecificS3Actions",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          "${aws_s3_bucket.J-company-backup.arn}",
          "${aws_s3_bucket.J-company-backup.arn}/*/*"
        ],
        "Condition" : {
          "StringNotEquals" : {
            "s3:prefix" : [
              "",
              "/"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_security_group" "J-company-sqs" {
  name = "J-company-ep-sqs-SG"
  vpc_id = aws_vpc.J-company.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }
    tags = {
    Name = "J-company-ep-sqs-SG"
  }
}

resource "aws_vpc_endpoint" "J-company-sqs" {
  vpc_id            = aws_vpc.J-company.id
  service_name      = "com.amazonaws.ap-northeast-2.sqs"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.J-company-sqs.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "J-company-sqs-endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "J-company-private_a" {
  vpc_endpoint_id = aws_vpc_endpoint.J-company-sqs.id
  subnet_id       = aws_subnet.J-company-private_a.id
}
resource "aws_vpc_endpoint_subnet_association" "J-company-public_b" {
  vpc_endpoint_id = aws_vpc_endpoint.J-company-sqs.id
  subnet_id       = aws_subnet.J-company-public_a.id
}
