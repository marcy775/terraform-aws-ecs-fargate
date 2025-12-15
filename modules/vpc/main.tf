# VPC
resource "aws_vpc" "tf_vpc" {
    cidr_block = var.vpc_cidr
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
resource "aws_route_table" "tf_route_table" {
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
  route_table_id = aws_route_table.tf_route_table.id
}