resource "aws_vpc" "busan-IAM-main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wsi-project-vpc"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "busan-IAM-main" {
  vpc_id = aws_vpc.busan-IAM-main.id

  tags = {
    Name = "wsi-project-igw"
  }
}

## Route Table
resource "aws_route_table" "busan-IAM-public" {
  vpc_id = aws_vpc.busan-IAM-main.id

  tags = {
    Name = "wsi-project-pub-rt"
  }
}
 
resource "aws_route" "busan-IAM-public" {
  route_table_id = aws_route_table.busan-IAM-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.busan-IAM-main.id
}

## Public Subnet
resource "aws_subnet" "busan-IAM-public_a" {
  vpc_id = aws_vpc.busan-IAM-main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsi-project-pub-a"
  }
}

resource "aws_subnet" "busan-IAM-public_b" {
  vpc_id = aws_vpc.busan-IAM-main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsi-project-pub-b"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "busan-IAM-public_a" {
  subnet_id = aws_subnet.busan-IAM-public_a.id
  route_table_id = aws_route_table.busan-IAM-public.id
}

resource "aws_route_table_association" "busan-IAM-public_b" {
  subnet_id = aws_subnet.busan-IAM-public_b.id
  route_table_id = aws_route_table.busan-IAM-public.id
}

# Private

## Elastic IP
resource "aws_eip" "busan-IAM-private_a" {
}

resource "aws_eip" "busan-IAM-private_b" {
}

## NAT Gateway
resource "aws_nat_gateway" "busan-IAM-private_a" {
  depends_on = [aws_internet_gateway.busan-IAM-main]

  allocation_id = aws_eip.busan-IAM-private_a.id
  subnet_id = aws_subnet.busan-IAM-public_a.id

  tags = {
    Name = "wsi-project-nat-a"
  }
}

resource "aws_nat_gateway" "busan-IAM-private_b" {
  depends_on = [aws_internet_gateway.busan-IAM-main]

  allocation_id = aws_eip.busan-IAM-private_b.id
  subnet_id = aws_subnet.busan-IAM-public_b.id

  tags = {
    Name = "wsi-project-nat-b"
  }
}

## Route Table
resource "aws_route_table" "busan-IAM-private_a" {
  vpc_id = aws_vpc.busan-IAM-main.id

  tags = {
    Name = "wsi-project-priv-a-rt"
  }
}

resource "aws_route_table" "busan-IAM-private_b" {
  vpc_id = aws_vpc.busan-IAM-main.id

  tags = {
    Name = "wsi-project-priv-b-rt"
  }
}

resource "aws_route" "busan-IAM-private_a" {
  route_table_id = aws_route_table.busan-IAM-private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.busan-IAM-private_a.id
}

resource "aws_route" "busan-IAM-private_b" {
  route_table_id = aws_route_table.busan-IAM-private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.busan-IAM-private_b.id
}

resource "aws_subnet" "busan-IAM-private_a" {
  vpc_id = aws_vpc.busan-IAM-main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsi-project-priv-a"
  }
}

resource "aws_subnet" "busan-IAM-private_b" {
  vpc_id = aws_vpc.busan-IAM-main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "wsi-project-priv-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "busan-IAM-private_a" {
  subnet_id = aws_subnet.busan-IAM-private_a.id
  route_table_id = aws_route_table.busan-IAM-private_a.id
}

resource "aws_route_table_association" "busan-IAM-private_b" {
  subnet_id = aws_subnet.busan-IAM-private_b.id
  route_table_id = aws_route_table.busan-IAM-private_b.id
}