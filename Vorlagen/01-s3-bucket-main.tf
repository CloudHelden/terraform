# S3 Bucket
# Dokumentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

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

# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "mein-erster-s3-bucket"

  tags = {
    Name = "Mein erster S3 Bucket"
  }
}
