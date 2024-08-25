resource "aws_vpc" "chungnam-main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gm-vpc"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "chungnam-main" {
  vpc_id = aws_vpc.chungnam-main.id

  tags = {
    Name = "gm-igw"
  }
}

## Route Table
resource "aws_route_table" "chungnam-public" {
  vpc_id = aws_vpc.chungnam-main.id

  tags = {
    Name = "gm-public-rtb"
  }
}

resource "aws_route" "chungnam-public" {
  route_table_id = aws_route_table.chungnam-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.chungnam-main.id
}

## Public Subnet
resource "aws_subnet" "chungnam-public_a" {
  vpc_id = aws_vpc.chungnam-main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "gm-pub-sn-a"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "chungnam-public_a" {
  subnet_id = aws_subnet.chungnam-public_a.id
  route_table_id = aws_route_table.chungnam-public.id
}

# Private
## Route Table
resource "aws_route_table" "chungnam-private_a" {
  vpc_id = aws_vpc.chungnam-main.id

  tags = {
    Name = "gm-private-rtb-a"
  }
}

resource "aws_route_table" "chungnam-private_b" {
  vpc_id = aws_vpc.chungnam-main.id

  tags = {
    Name = "gm-private-rtb-b"
  }
}

resource "aws_subnet" "chungnam-private_a" {
  vpc_id = aws_vpc.chungnam-main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gm-pri-sn-a"
  }
}

resource "aws_subnet" "chungnam-private_b" {
  vpc_id = aws_vpc.chungnam-main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gm-pri-sn-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "chungnam-private_a" {
  subnet_id = aws_subnet.chungnam-private_a.id
  route_table_id = aws_route_table.chungnam-private_a.id
}

resource "aws_route_table_association" "chungnam-private_b" {
  subnet_id = aws_subnet.chungnam-private_b.id
  route_table_id = aws_route_table.chungnam-private_b.id
}


resource "aws_vpc_endpoint" "chungnam-db" {
  vpc_id            = aws_vpc.chungnam-main.id
  service_name      = "com.amazonaws.ap-northeast-2.dynamodb"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "dynamodb-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "chungnam-private_a" {
  route_table_id  = aws_route_table.chungnam-private_a.id
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-db.id
}

resource "aws_vpc_endpoint_route_table_association" "chungnam-private_b" {
  route_table_id  = aws_route_table.chungnam-private_b.id
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-db.id
}

resource "aws_vpc_endpoint_policy" "chungnam-example" {
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-db.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "dynamodb:*"
        ],
        "Resource" : ["${aws_dynamodb_table.chungnam-order-table.arn}"]
      }
    ]
  })
}

resource "aws_vpc_endpoint" "chungnam-s3" {
  vpc_id            = aws_vpc.chungnam-main.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "chungnam-s3_private_a" {
  route_table_id  = aws_route_table.chungnam-private_a.id
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-s3.id
}

resource "aws_vpc_endpoint_route_table_association" "chungnam-s3_private_b" {
  route_table_id  = aws_route_table.chungnam-private_b.id
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-s3.id
}


resource "aws_security_group" "chungnam-ep-sg" {
  name = "ep-sg"
  vpc_id = aws_vpc.chungnam-main.id
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
    tags = {
    Name = "ep-sg"
  }
}

resource "aws_vpc_endpoint" "chungnam-elb" {
  vpc_id            = aws_vpc.chungnam-main.id
  service_name      = "com.amazonaws.ap-northeast-2.elasticloadbalancing"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.chungnam-ep-sg.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "elb-endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "chungnam-elb-private_a" {
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-elb.id
  subnet_id  = aws_subnet.chungnam-private_a.id
}

resource "aws_vpc_endpoint_subnet_association" "chungnam-elb-private_b" {
  vpc_endpoint_id = aws_vpc_endpoint.chungnam-elb.id
  subnet_id  = aws_subnet.chungnam-private_b.id
}

# # OutPut

# ## VPC
# output "aws_vpc" {
#   value = aws_vpc.chungnam-main.id
# }

# ## Public Subnet
# output "public_a" {
#   value = aws_subnet.public_a.id
# }

# ## Private Subnet
# output "private_a" {
#   value = aws_subnet.private_a.id
# }

# output "private_b" {
#   value = aws_subnet.private_b.id
# }