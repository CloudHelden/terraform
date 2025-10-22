# Lösung: S3 Bucket mit Versioning

# Random Suffix für eindeutigen Bucket-Namen
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket erstellen
resource "aws_s3_bucket" "main" {
  bucket = "terraform-uebung-${random_id.suffix.hex}"

  tags = {
    Name        = "Terraform Übung Bucket"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}

# Versioning separat aktivieren (ab AWS Provider v4+)
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Outputs
output "bucket_name" {
  description = "Der Name des erstellten S3 Buckets"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "Der ARN des Buckets"
  value       = aws_s3_bucket.main.arn
}
