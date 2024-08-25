resource "aws_vpc" "gyeongbuk-main" {
  cidr_block = "10.150.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gyeongbuk-vpc"
  }
}

# Public
## Internet Gateway
resource"aws_internet_gateway" "gyeongbuk-main" {
  vpc_id = aws_vpc.gyeongbuk-main.id

  tags = {
    Name = "gyeongbuk-igw"
  }
}

## Route Table
resource "aws_route_table" "gyeongbuk-public" {
  vpc_id = aws_vpc.gyeongbuk-main.id

  tags = {
    Name = "gyeongbuk-public-rt"
  }
}

resource "aws_route" "gyeongbuk-public" {
  route_table_id = aws_route_table.gyeongbuk-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gyeongbuk-main.id
}

## Public Subnet
resource "aws_subnet" "gyeongbuk-public_a" {
  vpc_id = aws_vpc.gyeongbuk-main.id
  cidr_block = "10.150.10.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "gyeongbuk-public-a"
  }
}

resource "aws_subnet" "gyeongbuk-public_b" {
  vpc_id = aws_vpc.gyeongbuk-main.id
  cidr_block = "10.150.11.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "gyeongbuk-public-b"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "gyeongbuk-public_a" {
  subnet_id = aws_subnet.gyeongbuk-public_a.id
  route_table_id = aws_route_table.gyeongbuk-public.id
}

resource "aws_route_table_association" "gyeongbuk-public_b" {
  subnet_id = aws_subnet.gyeongbuk-public_b.id
  route_table_id = aws_route_table.gyeongbuk-public.id
}

# Private

## Elastic IP
resource "aws_eip" "gyeongbuk-private_a" {
}

resource "aws_eip" "gyeongbuk-private_b" {
}

## NAT Gateway
resource "aws_nat_gateway" "gyeongbuk-private_a" {
  depends_on = [aws_internet_gateway.gyeongbuk-main]

  allocation_id = aws_eip.gyeongbuk-private_a.id
  subnet_id = aws_subnet.gyeongbuk-public_a.id

  tags = {
    Name = "gyeongbuk-natgw-a"
  }
}

resource "aws_nat_gateway" "gyeongbuk-private_b" {
  depends_on = [aws_internet_gateway.gyeongbuk-main]

  allocation_id = aws_eip.gyeongbuk-private_b.id
  subnet_id = aws_subnet.gyeongbuk-public_b.id

  tags = {
    Name = "gyeongbuk-natgw-b"
  }
}

## Route Table
resource "aws_route_table" "gyeongbuk-private_a" {
  vpc_id = aws_vpc.gyeongbuk-main.id

  tags = {
    Name = "gyeongbuk-priv-a-rt"
  }
}

resource "aws_route_table" "gyeongbuk-private_b" {
  vpc_id = aws_vpc.gyeongbuk-main.id

  tags = {
    Name = "gyeongbuk-priv-b-rt"
  }
}

resource "aws_route" "gyeongbuk-private_a" {
  route_table_id = aws_route_table.gyeongbuk-private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gyeongbuk-private_a.id
}

resource "aws_route" "gyeongbuk-private_b" {
  route_table_id = aws_route_table.gyeongbuk-private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gyeongbuk-private_b.id
}

resource "aws_subnet" "gyeongbuk-private_a" {
  vpc_id = aws_vpc.gyeongbuk-main.id
  cidr_block = "10.150.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gyeongbuk-priv-a"
  }
}

resource "aws_subnet" "gyeongbuk-private_b" {
  vpc_id = aws_vpc.gyeongbuk-main.id
  cidr_block = "10.150.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gyeongbuk-priv-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "gyeongbuk-private_a" {
  subnet_id = aws_subnet.gyeongbuk-private_a.id
  route_table_id = aws_route_table.gyeongbuk-private_a.id
}

resource "aws_route_table_association" "gyeongbuk-private_b" {
  subnet_id = aws_subnet.gyeongbuk-private_b.id
  route_table_id = aws_route_table.gyeongbuk-private_b.id
}

output "vpc" {
  value = aws_vpc.gyeongbuk-main.id
}

output "public_a" {
  value = aws_subnet.gyeongbuk-public_a.id
}

output "public_b" {
  value = aws_subnet.gyeongbuk-public_b.id
}

output "private_a" {
  value = aws_subnet.gyeongbuk-private_a.id
}

output "private_b" {
  value = aws_subnet.gyeongbuk-private_a.id
}