# VPC (Virtual Private Cloud)
# Dokumentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Einfache VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet in der VPC
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
}

# Internet Gateway 
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }
}

# Subnet mit Route Table verbinden
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

/*
WEITERE EIGENSCHAFTEN FÜR VPC:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

Erweiterungsmöglichkeiten:
- Private Subnets: aws_subnet (mit private=true)
- NAT Gateway: aws_nat_gateway (für Private Subnets)
- VPC Peering: aws_vpc_peering_connection
- VPN Connection: aws_vpn_connection
- Network ACLs: aws_network_acl
- Security Groups: aws_security_group

Weitere Ressourcen:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
*/
