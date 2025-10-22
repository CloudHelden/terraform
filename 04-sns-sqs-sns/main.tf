# ============================================================================
# PROVIDER KONFIGURATION
# ============================================================================

terraform {
  required_version = ">= 1.0"

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

# Data Source für AWS Account ID
data "aws_caller_identity" "current" {}

# ============================================================================
# VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS Region für die Ressourcen"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment Name (z.B. dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "message_retention_seconds" {
  description = "Wie lange Messages in der SQS Queue bleiben (in Sekunden)"
  type        = number
  default     = 240 # 4 Minuten
}

variable "visibility_timeout_seconds" {
  description = "Visibility Timeout für SQS Queue (in Sekunden)"
  type        = number
  default     = 30
}

# ============================================================================
# SNS TOPIC (Geführt - 70% vorgegeben)
# ============================================================================

# SNS Topic für eingehende Messages
resource "aws_sns_topic" "source" {
  name         = "${var.environment}-sns-sqs-topic"
  display_name = "SNS Source Topic"

  tags = {
    Name        = "${var.environment}-sns-topic"
    Environment = var.environment
    Purpose     = "Message Source"
  }
}

# SNS Topic Policy (wer darf publishen?)
resource "aws_sns_topic_policy" "source" {
  arn = aws_sns_topic.source.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "SNS:Publish",
          "SNS:GetTopicAttributes"
        ]
        Resource = aws_sns_topic.source.arn
      }
    ]
  })
}

# ============================================================================
# SQS QUEUE (Halb-selbstständig - 50% vorgegeben)
# ============================================================================

# SQS Queue für Message-Speicherung
resource "aws_sqs_queue" "main" {
  name = "${var.environment}-sns-sqs-queue"

  # Message Retention Period setzen
  message_retention_seconds = var.message_retention_seconds

  # Visibility Timeout setzen
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Tags hinzufügen
  tags = {
    Name        = "${var.environment}-sqs-queue"
    Environment = var.environment
    Purpose     = "Message Buffer"
  }
}

# SQS Queue Policy - erlaubt SNS das Senden von Messages
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.source.arn
          }
        }
      }
    ]
  })
}

# ============================================================================
# SUBSCRIPTIONS
# ============================================================================

# Subscription: SNS Topic → SQS Queue
resource "aws_sns_topic_subscription" "source_to_sqs" {
  topic_arn = aws_sns_topic.source.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn

  # Raw Message Delivery = false (SNS Envelope wird beibehalten)
  raw_message_delivery = false
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "sns_topic_arn" {
  description = "ARN des SNS Topics"
  value       = aws_sns_topic.source.arn
}

output "sqs_queue_url" {
  description = "URL der SQS Queue"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "ARN der SQS Queue"
  value       = aws_sqs_queue.main.arn
}

output "test_command_publish" {
  description = "AWS CLI Command zum Testen"
  value       = "aws sns publish --topic-arn ${aws_sns_topic.source.arn} --subject 'Test Message' --message 'Hello from Terraform!'"
}

output "test_command_receive" {
  description = "AWS CLI Command zum Empfangen von Messages"
  value       = "aws sqs receive-message --queue-url ${aws_sqs_queue.main.url}"
}
