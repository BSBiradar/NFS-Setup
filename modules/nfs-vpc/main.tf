# Creating a Custom VPC

resource "aws_vpc" "nfs_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.project}-vpc"
    env  = var.env
  }
}

# Creating the public subnet

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.nfs_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    env  = var.env
    Name = "${var.project}-public-subnet"
  }
}

# Creating the Internet Gateway (IGW)

resource "aws_internet_gateway" "nfs_igw" {
  vpc_id = aws_vpc.nfs_vpc.id
  tags = {
    env  = var.env
    Name = "${var.project}-igw"
  }
}

# Creating the public route table

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.nfs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nfs_igw.id
  }

  tags = {
    Name = "${var.project}-public-route-table"
  }
}

# Association public subnet with public route table

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

# Creating the private subnet

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.nfs_vpc.id
  cidr_block = var.private_subnet_cidr
  tags = {
    env  = var.env
    Name = "${var.project}-private-subnet"
  }
}

# Creating a private route table

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.nfs_vpc.id

  tags = {
    Name = "${var.project}-private-route-table"
  }
}

# Creating an Elastic IP for the NAT Gateway

resource "aws_eip" "nat_eip" {
  tags = {
    Name = "${var.project}-nat-eip"
  }
}

# Creating the NAT Gateway and association with the Elastic IP

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.nfs_igw]

  tags = {
    Name = "${var.project}-nat-gateway"
  }
}

#creating private route table

resource "aws_route" "private_route_nat" {
  route_table_id         = aws_route_table.private_route.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# Association of private subnet with private route table containing NAT Gateway route

resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}
