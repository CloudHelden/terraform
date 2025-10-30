# AWS SDK Demo - Lambda mit SQS, S3 und SNS

## Struktur

```
03-aws-sdk/
├── main.tf              # Terraform Konfiguration
├── src/
│   ├── package.json     # Dependencies (AWS SDK v3)
│   ├── sqs-handler.js   # Lambda für SQS Operationen
│   ├── s3-handler.js    # Lambda für S3 Operationen
│   └── sns-handler.js   # Lambda für SNS Operationen
└── README.md
```

## AWS Ressourcen

Das Terraform-Script erstellt:
- **SQS Queue** mit zufälligem Namen
- **S3 Bucket** mit zufälligem Namen
- **SNS Topic** mit zufälligem Namen
- **3 Lambda-Funktionen** (jeweils für SQS, S3 und SNS)
- **IAM Role** mit Berechtigungen für alle Services

Alle Lambdas haben Zugriff auf alle Ressourcen über Environment Variables:
- `SQS_QUEUE_URL`
- `SQS_QUEUE_ARN`
- `S3_BUCKET_NAME`
- `S3_BUCKET_ARN`
- `SNS_TOPIC_ARN`

## Deployment

### 1. Dependencies installieren

```bash
cd src
npm install
cd ..
```

### 2. Terraform ausführen

Terraform erstellt automatisch das ZIP-Archive aus dem `src` Ordner:

```bash
terraform init
terraform apply
```

## Aufräumen

```bash
terraform destroy
```
