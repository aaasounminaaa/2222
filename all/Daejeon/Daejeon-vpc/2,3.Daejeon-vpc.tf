resource "aws_vpc" "daejeon-main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wsi-vpc"
  }
}

# Public
## Internet Gateway
resource"aws_internet_gateway" "daejeon-main" {
  vpc_id = aws_vpc.daejeon-main.id

  tags = {
    Name = "wsi-IGW"
  }
}

## Route Table
resource "aws_route_table" "daejeon-public" {
  vpc_id = aws_vpc.daejeon-main.id

  tags = {
    Name = "wsi-public-rt"
  }
}

resource "aws_route" "daejeon-public" {
  route_table_id = aws_route_table.daejeon-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.daejeon-main.id
}

## Public Subnet
resource "aws_subnet" "daejeon-public_a" {
  vpc_id = aws_vpc.daejeon-main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsi-public-a"
  }
}

resource "aws_subnet" "daejeon-public_b" {
  vpc_id = aws_vpc.daejeon-main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsi-public-b"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "daejeon-public_a" {
  subnet_id = aws_subnet.daejeon-public_a.id
  route_table_id = aws_route_table.daejeon-public.id
}

resource "aws_route_table_association" "daejeon-public_b" {
  subnet_id = aws_subnet.daejeon-public_b.id
  route_table_id = aws_route_table.daejeon-public.id
}

# Private

## Elastic IP
resource "aws_eip" "daejeon-private_a" {
}

resource "aws_eip" "daejeon-private_b" {
}

## NAT Gateway
resource "aws_nat_gateway" "daejeon-private_a" {
  depends_on = [aws_internet_gateway.daejeon-main]

  allocation_id = aws_eip.daejeon-private_a.id
  subnet_id = aws_subnet.daejeon-public_a.id

  tags = {
    Name = "wsi-NGW-a"
  }
}

resource "aws_nat_gateway" "daejeon-private_b" {
  depends_on = [aws_internet_gateway.daejeon-main]

  allocation_id = aws_eip.daejeon-private_b.id
  subnet_id = aws_subnet.daejeon-public_b.id

  tags = {
    Name = "wsi-NGW-b"
  }
}

## Route Table
resource "aws_route_table" "daejeon-private_a" {
  vpc_id = aws_vpc.daejeon-main.id

  tags = {
    Name = "wsi-private-a-rt"
  }
}

resource "aws_route_table" "daejeon-private_b" {
  vpc_id = aws_vpc.daejeon-main.id

  tags = {
    Name = "wsi-private-b-rt"
  }
}

resource "aws_route" "daejeon-private_a" {
  route_table_id = aws_route_table.daejeon-private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.daejeon-private_a.id
}

resource "aws_route" "daejeon-private_b" {
  route_table_id = aws_route_table.daejeon-private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.daejeon-private_b.id
}

resource "aws_subnet" "daejeon-private_a" {
  vpc_id = aws_vpc.daejeon-main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsi-private-a"
  }
}

resource "aws_subnet" "daejeon-private_b" {
  vpc_id = aws_vpc.daejeon-main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "wsi-private-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "daejeon-private_a" {
  subnet_id = aws_subnet.daejeon-private_a.id
  route_table_id = aws_route_table.daejeon-private_a.id
}

resource "aws_route_table_association" "daejeon-private_b" {
  subnet_id = aws_subnet.daejeon-private_b.id
  route_table_id = aws_route_table.daejeon-private_b.id
}

# OutPut

## VPC
output "aws_vpc" {
  value = aws_vpc.daejeon-main.id
}

# ## Public Subnet
output "public_a" {
  value = aws_subnet.daejeon-public_a.id
}

output "public_b" {
  value = aws_subnet.daejeon-public_b.id
}

## Private Subnet
output "private_a" {
  value = aws_subnet.daejeon-private_a.id
}

output "private_b" {
  value = aws_subnet.daejeon-private_b.id
}