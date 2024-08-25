resource "aws_vpc" "Jeju-gvn" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "cg-vpc"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "Jeju-gvn" {
  vpc_id = aws_vpc.Jeju-gvn.id

  tags = {
    Name = "cg-IGW"
  }
}

## Route Table
resource "aws_route_table" "Jeju-gvn-public" {
  vpc_id = aws_vpc.Jeju-gvn.id

  tags = {
    Name = "cg-public-rt"
  }
}
 
resource "aws_route" "Jeju-gvn-public" {
  route_table_id = aws_route_table.Jeju-gvn-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.Jeju-gvn.id
}

## Public Subnet
resource "aws_subnet" "Jeju-gvn-public_a" {
  vpc_id = aws_vpc.Jeju-gvn.id
  cidr_block = "10.0.100.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cg-public-sn-a"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "Jeju-gvn-public_a" {
  subnet_id = aws_subnet.Jeju-gvn-public_a.id
  route_table_id = aws_route_table.Jeju-gvn-public.id
}