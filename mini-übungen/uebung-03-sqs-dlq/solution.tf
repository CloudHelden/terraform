# Lösung: SQS Queue mit Dead Letter Queue

# Dead Letter Queue (DLQ) - hierhin kommen failed messages
resource "aws_sqs_queue" "dead_letter" {
  name                      = "terraform-uebung-dlq"
  message_retention_seconds = 1209600 # 14 Tage

  tags = {
    Name      = "Terraform Übung DLQ"
    ManagedBy = "terraform"
  }
}

# Haupt-Queue mit Redrive Policy
resource "aws_sqs_queue" "main" {
  name                       = "terraform-uebung-main-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 Tage

  # Redrive Policy: Nach 3 fehlgeschlagenen Versuchen → DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name      = "Terraform Übung Main Queue"
    ManagedBy = "terraform"
  }
}

# Outputs
output "main_queue_url" {
  description = "URL der Haupt-Queue"
  value       = aws_sqs_queue.main.url
}

output "main_queue_arn" {
  description = "ARN der Haupt-Queue"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL der Dead Letter Queue"
  value       = aws_sqs_queue.dead_letter.url
}

output "dlq_arn" {
  description = "ARN der Dead Letter Queue"
  value       = aws_sqs_queue.dead_letter.arn
}

output "max_receive_count" {
  description = "Anzahl Versuche bevor Message in DLQ wandert"
  value       = 3
}
