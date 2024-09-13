provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "insurnace-claims-vpc" {
  cidr_block           = var.rds_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name       = "insurance-claims-vpc"
    created_by = "terraform"
  }
}

resource "aws_subnet" "insurnace-claims-subnet-az1" {
  vpc_id            = aws_vpc.insurnace-claims-vpc.id
  cidr_block        = var.rds_subnet_1_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name       = "insurnace-claims-subnet-az1"
    created_by = "terraform"
  }
}

resource "aws_subnet" "insurnace-claims-subnet-az2" {
  vpc_id            = aws_vpc.insurnace-claims-vpc.id
  cidr_block        = var.rds_subnet_2_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name       = "insurance-claims-subnet-az2"
    created_by = "terraform"
  }
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  depends_on = [
    aws_subnet.insurnace-claims-subnet-az1,
    aws_subnet.insurnace-claims-subnet-az2,
  ]

  name       = "insurance-claims-subnet-group"
  subnet_ids = [aws_subnet.insurnace-claims-subnet-az1.id, aws_subnet.insurnace-claims-subnet-az2.id]

  tags = {
    Name       = "insurance-claims-subnet-group"
    created_by = "terraform"
  }
}

resource "aws_internet_gateway" "insurnace-rds-igw" {
  vpc_id = aws_vpc.insurnace-claims-vpc.id

  tags = {
    Name       = "insurance-rds-igw"
    created_by = "terraform"
  }
}

resource "aws_route_table" "rds-rt-igw" {
  vpc_id = aws_vpc.insurnace-claims-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.insurnace-rds-igw.id
  }

  tags = {
    Name       = "rds-public-route-igw"
    created_by = "terraform"
  }
}

resource "aws_route_table_association" "rds-subnet-rt-association-igw-az1" {
  subnet_id      = aws_subnet.insurnace-claims-subnet-az1.id
  route_table_id = aws_route_table.rds-rt-igw.id
}

resource "aws_route_table_association" "rds-subnet-rt-association-igw-az2" {
  subnet_id      = aws_subnet.insurnace-claims-subnet-az2.id
  route_table_id = aws_route_table.rds-rt-igw.id
}

resource "aws_security_group" "rds_security_group" {
  name        = "insurance_claims_rds_security_group_1c5cdecc"
  description = "Security Group for RDS Oracle instance. Used in Confluent Cloud claims processing prototype."
  vpc_id      = aws_vpc.insurnace-claims-vpc.id

  ingress {
    description = "RDS Oracle Port"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "insurance-claims-rds-security-group"
    created_by = "terraform"
  }
}

resource "aws_db_instance" "insurance-customers" {
  identifier             = var.rds_instance_identifier
  engine                 = "oracle-se2"
  engine_version         = "19"
  instance_class         = var.rds_instance_class
  username               = var.rds_username
  password               = var.rds_password
  port                   = 1521
  license_model          = "license-included"
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  allocated_storage   = 20
  storage_encrypted   = false
  skip_final_snapshot = true
  publicly_accessible = true
  tags = {
    name       = "insurance-customers"
    created_by = "terraform"
  }
}

