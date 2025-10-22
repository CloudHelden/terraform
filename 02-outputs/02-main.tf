# Outputs - Ergebnisse ausgeben
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

# VARIABLES
variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "instance_name" {
  type    = string
  default = "my-server"
}

variable "instance_count" {
  type    = number
  default = 1
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
  map_public_ip_on_launch = true

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

# EC2 Instances
resource "aws_instance" "web" {
  count           = var.instance_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.main.id

  tags = { Name = "${var.instance_name}-${count.index + 1}" }
}

# ============================================================================
# OUTPUTS - Ergebnisse ausgeben
# ============================================================================

# 1. STRING Output - Einzelner Wert
output "first_instance_id" {
  description = "ID der ersten Instanz"
  value       = aws_instance.web[0].id
}

# 2. LIST Output - Array von Werten (splat syntax)
output "instance_ids" {
  description = "IDs aller erstellten Instanzen"
  value       = aws_instance.web[*].id
}

# 3. LIST Output - Public IPs
output "instance_public_ips" {
  description = "Öffentliche IP Adressen der Instanzen"
  value       = aws_instance.web[*].public_ip
}

# 4. MAP Output - Key-Value Paare
output "instance_details" {
  description = "Details zu den Instanzen"
  value = {
    instance_count = var.instance_count
    instance_type  = "t3.micro"
    ami_id         = data.aws_ami.ubuntu.id
  }
}

# 5. OBJECT Output - Komplexe Struktur
output "deployment_summary" {
  description = "Übersicht des gesamten Deployments"
  value = {
    instances = {
      count = var.instance_count
      ids   = aws_instance.web[*].id
      ips   = aws_instance.web[*].public_ip
    }
  }
}

# 6. SENSITIVE Output - Für sensitive Daten
output "instance_private_ips" {
  description = "Private IP Adressen (sensitive)"
  value       = aws_instance.web[*].private_ip
  sensitive   = true
}
