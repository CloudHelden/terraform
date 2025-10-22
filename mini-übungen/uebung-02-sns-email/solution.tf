# Lösung: SNS Topic mit Email Subscription

# Variable für Email-Adresse
variable "email_address" {
  description = "Deine Email für SNS Notifications"
  type        = string
  default     = "deine.email@example.com"
}

# SNS Topic erstellen
resource "aws_sns_topic" "notifications" {
  name         = "terraform-uebung-notifications"
  display_name = "Terraform Übung Notifications"

  tags = {
    Name      = "Terraform Übung Topic"
    ManagedBy = "terraform"
  }
}

# Email Subscription zum Topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# Outputs
output "topic_arn" {
  description = "ARN des SNS Topics"
  value       = aws_sns_topic.notifications.arn
}

output "subscription_status" {
  description = "Status der Email-Subscription"
  value       = aws_sns_topic_subscription.email.pending_confirmation
}

output "next_steps" {
  description = "Was du als nächstes tun musst"
  value       = "Check deine Emails und bestätige die SNS Subscription!"
}
