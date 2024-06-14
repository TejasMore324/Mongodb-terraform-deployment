# main.tf

# Specify the AWS provider
provider "aws" {
  region = "us-east-1" # Adjust this to your desired AWS region
}

# Data source for AWS availability zones
data "aws_availability_zones" "available" {}

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC creation
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway for VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}_igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}_public"
  }
}

# Private Subnets for MongoDB Nodes
resource "aws_subnet" "private" {
  count             = var.num_secondary_nodes + 1
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.2.0/24", 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))

  tags = {
    Name = "${var.vpc_name}_private_${count.index}"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}_public_rt"
  }
}

# Associate Public Subnet with Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for Private Subnet
resource "aws_nat_gateway" "private" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.vpc_name}_nat_gw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private.id
  }

  tags = {
    Name = "${var.vpc_name}_private_rt"
  }
}

# Associate Private Subnets with Route Table
resource "aws_route_table_association" "private" {
  count          = var.num_secondary_nodes + 1
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}

# Security Group for Jumpbox
resource "aws_security_group" "jumpbox_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jumpbox_SG"
  }
}

# Security Group for MongoDB
resource "aws_security_group" "mongodb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Allow internal communication
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MongoDB_SG"
  }
}

# Key Pair for SSH Access
resource "aws_key_pair" "mongodb_key" {
  key_name   = "mongodb-key"
  public_key = file("~/.ssh/id_rsa.pub") # Update with the path to your public key
}

# Jumpbox Instance
resource "aws_instance" "jumpbox" {
  ami                    = data.aws_ami.amazon_linux_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.mongodb_key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]

  tags = {
    Name = "Jumpbox"
  }
}

# MongoDB Instances
resource "aws_instance" "mongodb" {
  count                  = var.num_secondary_nodes + 1
  ami                    = data.aws_ami.amazon_linux_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.mongodb_key.key_name
  subnet_id              = element(aws_subnet.private[*].id, count.index)
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  user_data              = file("mongodb_userdata.sh")

  tags = {
    Name = "MongoDB_Instance_${count.index}"
  }
}


# Output the Public IP of the Jumpbox
output "jumpbox_public_ip" {
  value = aws_instance.jumpbox.public_ip
}

# Output the MongoDB Instances' Private IPs
output "mongodb_private_ips" {
  value = aws_instance.mongodb[*].private_ip
}
