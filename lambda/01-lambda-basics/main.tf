# Terraform Configuration Block
# Definiert die erforderlichen Provider für dieses Projekt
# - aws: Für AWS-Ressourcen (Version >= 5.0)
# - archive: Zum Erstellen von ZIP-Archiven für Lambda-Code (Version >= 2.4.0)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}

# AWS Provider Configuration
# Konfiguriert die AWS-Region auf eu-north-1 (Stockholm)
provider "aws" {
  region = "eu-north-1"
}

# IAM Role für Lambda-Funktion
# Erstellt eine Rolle, die Lambda erlaubt, diese anzunehmen (AssumeRole)
# Die Trust Policy erlaubt dem Lambda-Service, diese Rolle zu verwenden
resource "aws_iam_role" "lambda_role" {
  name = "lambda_sqs_role-2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

# IAM Policy Attachment
# Hängt die AWS-Managed-Policy "AWSLambdaBasicExecutionRole" an die Lambda-Rolle an
# Diese Policy erlaubt Lambda, Logs in CloudWatch zu schreiben
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Archive Data Source
# Erstellt automatisch ein ZIP-Archiv aus dem Source-Code
# - source_dir: Nimmt alle Dateien aus ./src
# - output_path: Speichert das ZIP in ./build/lambda.zip
# Wird bei jedem terraform apply neu erstellt, wenn sich der Code ändert
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

# Lambda Function
# Erstellt die eigentliche Lambda-Funktion mit:
# - function_name: Name der Funktion in AWS
# - handler: index.handler (Datei: index.js, Export: handler)
# - runtime: Node.js 20.x
# - role: Verwendet die oben erstellte IAM-Rolle
# - filename: Das ZIP-Archiv aus dem archive_file data source
# - source_code_hash: Hash für automatische Updates bei Code-Änderungen
resource "aws_lambda_function" "hello" {
  function_name = "hello_lambda"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}
