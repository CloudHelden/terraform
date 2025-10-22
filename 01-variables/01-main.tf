# Input Variables und Variable Types
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

# STRING - Textwerte
variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-north-1"
}

variable "instance_name" {
  type    = string
  default = "my-server"
}
variable "environment" {
  type        = string
  default     = "development"
  description = "development, staging oder production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Nur development, staging oder production erlaubt!"
  }
}
# NUMBER - Zahlen
variable "instance_count" {
  type    = number
  default = 1
}

# BOOL - true/false
variable "enable_public_ip" {
  type    = bool
  default = true
}

# LIST - Array von Werten
variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "allowed_http_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR Blöcke für HTTP/HTTPS"
}


# MAP - Key-Value Paare
variable "instance_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "DevOps"
  }
}

# OBJECT - Komplexe Struktur
variable "instance_config" {
  type = object({
    instance_type = string
    volume_size   = number
  })
  default = {
    instance_type = "t3.micro"
    volume_size   = 20
  }
}

# VPC erstellen
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.instance_name}-vpc" }
}

# Subnet erstellen
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = var.enable_public_ip

  tags = { Name = "${var.instance_name}-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.instance_name}-igw" }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.instance_name}-rt" }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "main" {
  name   = "${var.instance_name}-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }
  ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidrs
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.instance_name}-sg" }
}

# Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data Source - Aktuelle Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  count                = var.instance_count
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_config.instance_type
  subnet_id            = aws_subnet.main.id
  security_groups      = []
  vpc_security_group_ids = [aws_security_group.main.id]

  root_block_device {
    volume_size = var.instance_config.volume_size
  }

tags = merge(var.instance_tags, { Environment = var.environment })
}

# Outputs
output "instance_ids" {
  value = aws_instance.web[*].id
}

output "public_ips" {
  value = aws_instance.web[*].public_ip
}
