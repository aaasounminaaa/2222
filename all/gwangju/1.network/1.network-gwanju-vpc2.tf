resource "aws_vpc" "main-2" {
  cidr_block = "10.0.1.0/24"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gwangju-VPC2"
  }
}

resource "aws_route_table" "private_a-2" {
  vpc_id = aws_vpc.main-2.id

  tags = {
    Name = "gwangju-private-a-2-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju-example,aws_ec2_transit_gateway_route_table_association.VPC-2 ]
}

resource "aws_subnet" "private_a-2" {
  vpc_id = aws_vpc.main-2.id
  cidr_block = "10.0.1.0/25"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gwangju-private-2-a"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "private_a-2" {
  subnet_id = aws_subnet.private_a-2.id
  route_table_id = aws_route_table.private_a-2.id
}
resource "aws_route" "vpc2-egress-pri-a-tgw" {
  route_table_id = aws_route_table.private_a-2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju-example.id
  depends_on = [ aws_ec2_transit_gateway.gwangju-example ]
}
#############################################
## Route Table
resource "aws_route_table" "private_b-2" {
  vpc_id = aws_vpc.main-2.id

  tags = {
    Name = "gwangju-private-2-b-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju-example ]
}
resource "aws_subnet" "private_b-2" {
  vpc_id = aws_vpc.main-2.id
  cidr_block = "10.0.1.128/25"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gwangju-private-2-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "private_b-2" {
  subnet_id = aws_subnet.private_b-2.id
  route_table_id = aws_route_table.private_b-2.id
}

resource "aws_route" "vpc2-egress-pri-b-tgw" {
  route_table_id = aws_route_table.private_b-2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju-example.id
  depends_on = [ aws_ec2_transit_gateway.gwangju-example,aws_ec2_transit_gateway_route_table_association.VPC-2 ]
}
resource "aws_vpc_endpoint" "ssm-2" {
  vpc_id            = aws_vpc.main-2.id
  service_name      = "com.amazonaws.ap-northeast-2.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssm-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-2.id
  subnet_id       = aws_subnet.private_a-2.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-2.id
  subnet_id       = aws_subnet.private_b-2.id
}

resource "aws_vpc_endpoint" "ssm-message-2" {
  vpc_id            = aws_vpc.main-2.id
  service_name      = "com.amazonaws.ap-northeast-2.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssmmessages-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-2.id
  subnet_id       = aws_subnet.private_a-2.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-2.id
  subnet_id       = aws_subnet.private_b-2.id
}

resource "aws_vpc_endpoint" "ec2-2" {
  vpc_id            = aws_vpc.main-2.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-2.id
  subnet_id       = aws_subnet.private_a-2.id
}

resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-2.id
  subnet_id       = aws_subnet.private_b-2.id
}
resource "aws_vpc_endpoint" "ec2-message-2" {
  vpc_id            = aws_vpc.main-2.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-message-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-2.id
  subnet_id       = aws_subnet.private_a-2.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-2.id
  subnet_id       = aws_subnet.private_b-2.id
}