# IAM Roles - AWS Rollen erstellen
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

variable "lambda_function_name" {
  type    = string
  default = "my-lambda"
}

variable "dynamodb_table_name" {
  type    = string
  default = "my-table"
}

# ============================================================================
# IAM ROLE - Lambda Rolle
# ============================================================================

# 1. Vertrauensbeziehung - Wer darf diese Rolle benutzen?
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# 2. IAM Role erstellen
resource "aws_iam_role" "lambda_role" {
  name               = "${var.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = { Name = "${var.lambda_function_name}-role" }
}

# ============================================================================
# IAM POLICY - Berechtigungen (DynamoDB Zugriff)
# ============================================================================

# Policy definieren - Was darf die Rolle machen?
data "aws_iam_policy_document" "lambda_dynamodb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.my_table.arn]
  }
}

# Policy an Rolle anhängen
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "${var.lambda_function_name}-dynamodb-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_dynamodb_policy.json
}

# ============================================================================
# DYNAMODB TABLE
# ============================================================================

resource "aws_dynamodb_table" "my_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = { Name = var.dynamodb_table_name }
}

# ============================================================================
# LAMBDA FUNCTION
# ============================================================================

# ZIP Datei mit Lambda Code vorbereiten
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function erstellen
resource "aws_lambda_function" "my_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name   = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.11"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.my_table.name
    }
  }

  tags = { Name = var.lambda_function_name }
}


# ============================================================================
# OUTPUTS
# ============================================================================

output "lambda_role_arn" {
  description = "ARN der Lambda Role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_function_arn" {
  description = "ARN der Lambda Function"
  value       = aws_lambda_function.my_lambda.arn
}

output "dynamodb_table_name" {
  description = "Name der DynamoDB Tabelle"
  value       = aws_dynamodb_table.my_table.name
}
