terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Random suffix für eindeutige Namen
resource "random_id" "suffix" {
  byte_length = 4
}

# SQS Queue
resource "aws_sqs_queue" "demo_queue" {
  name                      = "demo-queue-${random_id.suffix.hex}"
  visibility_timeout_seconds = 300
  message_retention_seconds = 345600

  tags = {
    Name = "AWS SDK Demo Queue"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "demo-bucket-${random_id.suffix.hex}"

  tags = {
    Name = "AWS SDK Demo Bucket"
  }
}

# SNS Topic
resource "aws_sns_topic" "demo_topic" {
  name = "demo-topic-${random_id.suffix.hex}"

  tags = {
    Name = "AWS SDK Demo Topic"
  }
}

# IAM Role für Lambda Funktionen
resource "aws_iam_role" "lambda_role" {
  name = "lambda-aws-sdk-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy für SQS
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda-sqs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy für S3
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy für SNS
resource "aws_iam_role_policy" "lambda_sns_policy" {
  name = "lambda-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy für CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "lambda-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ZIP Archive für Lambda Deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

# Lambda Function für SQS
resource "aws_lambda_function" "sqs_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "03-sdk-sqs-demo-${random_id.suffix.hex}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "sqs-handler.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.demo_queue.url
      SQS_QUEUE_ARN = aws_sqs_queue.demo_queue.arn
      S3_BUCKET_NAME = aws_s3_bucket.demo_bucket.id
      S3_BUCKET_ARN = aws_s3_bucket.demo_bucket.arn
      SNS_TOPIC_ARN = aws_sns_topic.demo_topic.arn
    }
  }

  tags = {
    Name = "SQS Demo Lambda"
  }
}

# Lambda Function für S3
resource "aws_lambda_function" "s3_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "03-sdk-s3-demo-${random_id.suffix.hex}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "s3-handler.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.demo_queue.url
      SQS_QUEUE_ARN = aws_sqs_queue.demo_queue.arn
      S3_BUCKET_NAME = aws_s3_bucket.demo_bucket.id
      S3_BUCKET_ARN = aws_s3_bucket.demo_bucket.arn
      SNS_TOPIC_ARN = aws_sns_topic.demo_topic.arn
    }
  }

  tags = {
    Name = "S3 Demo Lambda"
  }
}

# Lambda Function für SNS
resource "aws_lambda_function" "sns_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "03-sdk-sns-demo-${random_id.suffix.hex}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "sns-handler.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.demo_queue.url
      SQS_QUEUE_ARN = aws_sqs_queue.demo_queue.arn
      S3_BUCKET_NAME = aws_s3_bucket.demo_bucket.id
      S3_BUCKET_ARN = aws_s3_bucket.demo_bucket.arn
      SNS_TOPIC_ARN = aws_sns_topic.demo_topic.arn
    }
  }

  tags = {
    Name = "SNS Demo Lambda"
  }
}
