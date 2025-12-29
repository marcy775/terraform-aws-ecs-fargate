# VPC
resource "aws_vpc" "tf_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
      Name = "${var.name}-vpc"
    }
}

# public subnet
resource "aws_subnet" "tf_public_subnet" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-subnet-${var.azs[count.index]}"
  }
}


# private subnet
resource "aws_subnet" "tf_private_subnet" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}-private-subnet-${var.azs[count.index]}"
  }
}

# IGW
resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# public route table
resource "aws_route_table" "tf_public_route" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }

  tags = {
    Name = "${var.name}-public-route-table"
  }
}

# route table association
resource "aws_route_table_association" "public_subnet_cidrs" {
  count = length(var.public_subnet_cidrs)

  subnet_id = aws_subnet.tf_public_subnet[count.index].id
  route_table_id = aws_route_table.tf_public_route.id
}

# private route table
resource "aws_route_table" "tf_private_route" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "${var.name}-private-route-table"
  }
}

# route table association
resource "aws_route_table_association" "private_subnet_cidrs" {
  count = length(var.private_subnet_cidrs)

  subnet_id = aws_subnet.tf_private_subnet[count.index].id
  route_table_id = aws_route_table.tf_private_route.id
}


# VPC Endpoint SG
resource "aws_security_group" "tf_endpoint_sg" {
  name = "${var.name}-vpc-endpoint-sg"
  description = "Allow HTTPS from VPC"
  vpc_id = aws_vpc.tf_vpc.id
}

# VPC Endpoint SG inbound
resource "aws_vpc_security_group_ingress_rule" "endpoint_sg_inbound" {
  security_group_id = aws_security_group.tf_endpoint_sg.id

  ip_protocol = "tcp"
  from_port = 443
  to_port = 443
  cidr_ipv4 = aws_vpc.tf_vpc.cidr_block
}

# VPC Endpoint SG outbound
resource "aws_vpc_security_group_egress_rule" "endpoint_sg_outbound" {
  security_group_id = aws_security_group.tf_endpoint_sg.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

# VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id = aws_vpc.tf_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = aws_subnet.tf_private_subnet[*].id
  security_group_ids = [ aws_security_group.tf_endpoint_sg.id ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id = aws_vpc.tf_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = aws_subnet.tf_private_subnet[*].id
  security_group_ids = [ aws_security_group.tf_endpoint_sg.id ]
  private_dns_enabled = true
}

# CloudWatch Logs Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id = aws_vpc.tf_vpc.id
  service_name = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids = aws_subnet.tf_private_subnet[*].id
  security_group_ids = [ aws_security_group.tf_endpoint_sg.id ]
  private_dns_enabled = true
}

# S3 Endpoint
resource "aws_vpc_endpoint" "S3" {
  vpc_id = aws_vpc.tf_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.tf_private_route[*].id
}