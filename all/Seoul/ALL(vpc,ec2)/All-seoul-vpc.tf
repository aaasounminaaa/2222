resource "aws_vpc" "seoul-main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "seoul-vpc"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "seoul-main" {
  vpc_id = aws_vpc.seoul-main.id

  tags = {
    Name = "seoul-IGW"
  }
}

## Route Table
resource "aws_route_table" "seoul-public" {
  vpc_id = aws_vpc.seoul-main.id

  tags = {
    Name = "seoul-public-rt"
  }
}
 
resource "aws_route" "public" {
  route_table_id = aws_route_table.seoul-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.seoul-main.id
}

## Public Subnet
resource "aws_subnet" "seoul-public_a" {
  vpc_id = aws_vpc.seoul-main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "seoul-public-a"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "seoul-public_a" {
  subnet_id = aws_subnet.seoul-public_a.id
  route_table_id = aws_route_table.seoul-public.id
}

# OutPut

## VPC
output "seoul_aws_vpc" {
  value = aws_vpc.seoul-main.id
}

# ## Public Subnet
output "seoul_public_a" {
  value = aws_subnet.seoul-public_a.id
}

# output "bastion" {
#   value = aws_instance.bastion.id
# }

# output "bastion-sg" {
#   value = aws_security_group.bastion.id
# }