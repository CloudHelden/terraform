# Terraform-Konfigurationsblock: Definiert die erforderlichen Provider und deren Versionen
# Hier werden AWS (für Cloud-Ressourcen) und Archive (für das Zippen des Lambda-Codes) benötigt
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

# AWS-Provider-Konfiguration: Legt die AWS-Region fest, in der alle Ressourcen erstellt werden
# eu-north-1 = Stockholm
provider "aws" {
  region = "eu-north-1"
}

# IAM-Role für die Lambda-Funktion: Definiert die Rolle, die der Lambda-Funktion Berechtigungen gibt
# Die assume_role_policy erlaubt es dem Lambda-Service, diese Rolle zu übernehmen
resource "aws_iam_role" "lambda_role" {
  name = "lambda_sqs_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

# Policy-Attachment: Hängt die AWS-Standardrichtlinie für Lambda-Ausführung an die Rolle an
# Diese Policy erlaubt der Lambda-Funktion, Logs in CloudWatch zu schreiben
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom IAM-Policy für SQS-Zugriff: Erlaubt der Lambda-Funktion, Nachrichten an die SQS-Queue zu senden
# Diese Policy wird inline in die Lambda-Rolle eingebettet
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda_sqs_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.lambda_queue.arn
      }
    ]
  })
}

# SQS-Queue: Erstellt eine Simple Queue Service Queue zum Speichern von Nachrichten
# Die Lambda-Funktion kann Nachrichten an diese Queue senden
resource "aws_sqs_queue" "lambda_queue" {
  name = "lambda-queue"
}

# Archive Data Source: Zippt automatisch den Lambda-Code aus dem src-Verzeichnis
# Das resultierende ZIP-File wird im build-Ordner gespeichert und für das Lambda-Deployment verwendet
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

# Lambda-Funktion: Erstellt die eigentliche Lambda-Funktion in AWS
# - Verwendet das gezippte Code-Archiv als Deployment-Package
# - Wird mit der IAM-Rolle verknüpft, die zuvor erstellt wurde
# - Erhält die Queue-URL als Umgebungsvariable, damit der Code darauf zugreifen kann
resource "aws_lambda_function" "hello" {
  function_name = "hello_lambda"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.lambda_queue.url
    }
  }
}
