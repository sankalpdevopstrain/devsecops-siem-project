# ============================================================
# DevSecOps Platform — Terraform Config
# Provisions: VPC, Subnet, Security Group, EC2 instance
# Region: eu-west-2 (London)
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── VPC ───────────────────────────────────────────────────────
resource "aws_vpc" "devsecops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "devsecops-vpc"
    Project = "devsecops-siem"
  }
}

# ── Internet Gateway ──────────────────────────────────────────
resource "aws_internet_gateway" "devsecops_igw" {
  vpc_id = aws_vpc.devsecops_vpc.id

  tags = {
    Name    = "devsecops-igw"
    Project = "devsecops-siem"
  }
}

# ── Public Subnet ─────────────────────────────────────────────
resource "aws_subnet" "devsecops_subnet" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "devsecops-subnet"
    Project = "devsecops-siem"
  }
}

# ── Route Table ───────────────────────────────────────────────
resource "aws_route_table" "devsecops_rt" {
  vpc_id = aws_vpc.devsecops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devsecops_igw.id
  }

  tags = {
    Name    = "devsecops-rt"
    Project = "devsecops-siem"
  }
}

resource "aws_route_table_association" "devsecops_rta" {
  subnet_id      = aws_subnet.devsecops_subnet.id
  route_table_id = aws_route_table.devsecops_rt.id
}

# ── Security Group ────────────────────────────────────────────
resource "aws_security_group" "devsecops_sg" {
  name        = "devsecops-sg"
  description = "Security group for DevSecOps EC2 instance"
  vpc_id      = aws_vpc.devsecops_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Node.js app port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Node.js app"
  }

  # Outbound — allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "devsecops-sg"
    Project = "devsecops-siem"
  }
}

# ── Key Pair ─────────────────────────────────────────────────
resource "aws_key_pair" "devsecops_key" {
  key_name   = "devsecops-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDE/9HomHqLX9XCuHLGa9INJZyKJ/M8LIuTa01G2IePtxb+c6GvftndqbVmhgWgiWQUJ3PDGSmOFHD1TGDjKlnJAinBY4v6pJsrPalBwGAFsWiIZM9CGWiMReE7uh5zCPnPBItRU0Uaowu1E5bP7erUPtwvPEieK30dg8pYEK50uL3FTXO/0cVnGo1hkAOnYafmAFvJkdxdSASh5gJ8MjIH/sgigDVIHWlEkTRzeRnRH+4bLyDHIy/otY+gAaHvkAXncISJTWICbUWo70RLVMYdTKDm//7xPgmGy07kv/b5p3HkO5Er6X0ksFyTRNON3KM18rW79OePagJ9ruS1Zjvr"

  tags = {
    Name    = "devsecops-key"
    Project = "devsecops-siem"
  }
}

# ── EC2 Instance ──────────────────────────────────────────────
resource "aws_instance" "devsecops_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devsecops_key.key_name
  subnet_id              = aws_subnet.devsecops_subnet.id
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]

  user_data = templatefile("${path.module}/user_data/bootstrap.sh", {
    siem_url = var.siem_url
  })

  tags = {
    Name    = "devsecops-ec2"
    Project = "devsecops-siem"
  }
}
