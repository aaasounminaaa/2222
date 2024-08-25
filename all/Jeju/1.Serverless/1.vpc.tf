resource "aws_vpc" "Jeju-serverless" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "serverless-vpc"
  }
}

resource"aws_internet_gateway" "Jeju-serverless-igw" {
  vpc_id = aws_vpc.Jeju-serverless.id

  tags = {
    Name = "serverless-igw"
  }
}

resource "aws_route_table" "Jeju-serverless-public" {
  vpc_id = aws_vpc.Jeju-serverless.id

  tags = {
    Name = "serverless-public-rt"
  }
}

resource "aws_route" "Jeju-serverless-public" {
  route_table_id = aws_route_table.Jeju-serverless-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.Jeju-serverless-igw.id
}

resource "aws_subnet" "Jeju-serverless-public_a" {
  vpc_id = aws_vpc.Jeju-serverless.id
  cidr_block = "10.0.100.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "serverless-public-sn-a"
  }
}

resource "aws_route_table_association" "Jeju-serverless-public_a" {
  subnet_id = aws_subnet.Jeju-serverless-public_a.id
  route_table_id = aws_route_table.Jeju-serverless-public.id
}