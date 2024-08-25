resource "aws_vpc" "main-1" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gwangju-VPC1"
  }
}

resource "aws_route_table" "private_a-1" {
  vpc_id = aws_vpc.main-1.id

  tags = {
    Name = "gwangju-private-a-1-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju-example ]
}

resource "aws_subnet" "private_a-1" {
  vpc_id = aws_vpc.main-1.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gwangju-private-1-a"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "private_a-1" {
  subnet_id = aws_subnet.private_a-1.id
  route_table_id = aws_route_table.private_a-1.id
}

resource "aws_route" "vpc1-egress-pri-a-tgw" {
  route_table_id = aws_route_table.private_a-1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju-example.id
  depends_on = [ aws_ec2_transit_gateway.gwangju-example,aws_ec2_transit_gateway_vpc_attachment.VPC-1,aws_ec2_transit_gateway_route_table_association.VPC-1 ]
}
#############################################
## Route Table
resource "aws_route_table" "private_b-1" {
  vpc_id = aws_vpc.main-1.id

  tags = {
    Name = "gwangju-private-1-b-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju-example ]
}
resource "aws_subnet" "private_b-1" {
  vpc_id = aws_vpc.main-1.id
  cidr_block = "10.0.0.128/25"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gwangju-private-1-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "private_b-1" {
  subnet_id = aws_subnet.private_b-1.id
  route_table_id = aws_route_table.private_b-1.id
}
resource "aws_route" "vpc1-egress-pri-b-tgw" {
  route_table_id = aws_route_table.private_b-1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju-example.id
  depends_on = [ aws_ec2_transit_gateway.gwangju-example,aws_ec2_transit_gateway_vpc_attachment.VPC-1,aws_ec2_transit_gateway_route_table_association.VPC-1 ]
}

resource "aws_vpc_endpoint" "ssm-1" {
  vpc_id            = aws_vpc.main-1.id
  service_name      = "com.amazonaws.ap-northeast-2.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssm-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-1.id
  subnet_id       = aws_subnet.private_b-1.id
}

resource "aws_vpc_endpoint" "ssm-message-1" {
  vpc_id            = aws_vpc.main-1.id
  service_name      = "com.amazonaws.ap-northeast-2.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssmmessages-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-1.id
  subnet_id       = aws_subnet.private_b-1.id
}

resource "aws_vpc_endpoint" "ec2-1" {
  vpc_id            = aws_vpc.main-1.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-1.id
  subnet_id       = aws_subnet.private_b-1.id
}
resource "aws_vpc_endpoint" "ec2-message-1" {
  vpc_id            = aws_vpc.main-1.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-message-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-1.id
  subnet_id       = aws_subnet.private_b-1.id
}