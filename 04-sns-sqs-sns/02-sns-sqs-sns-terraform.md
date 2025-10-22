# SNS → SQS Integration - Terraform Implementation

## Übersicht
In dieser Aufgabe setzt du die Konsolen-Aufgabe in Terraform-Code um. Du nutzt dabei dein Wissen aus den vorherigen Modulen (Variables, Outputs, IAM Permissions).

**Ziel:**
- Infrastructure as Code für SNS → SQS Pipeline
- Wiederholbare, versionierbare Deployments
- Best Practices für Terraform-Struktur

---

## Projekt-Struktur

Erstelle folgende Dateien im Ordner `04-sns-sqs-sns/`:

```
04-sns-sqs-sns/
├── main.tf             # Alle Ressourcen in einer Datei
├── terraform.tfvars    # Variable Values
└── (outputs werden in main.tf definiert)
```

---

## Phase 1: Terraform-Datei erstellen

### Datei: `main.tf`

Erstelle die Haupt-Terraform-Datei mit allen Ressourcen:

```hcl
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
  default     = 240  # 4 Minuten
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
  display_name = "SNS Source Topic"  # TODO: Kann auch anders benannt werden

  tags = {
    Name        = "${var.environment}-sns-topic"
    Environment = var.environment
    Purpose     = "Message Source"  # TODO: Beschreibung des Zwecks
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
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"  # TODO: Account Root User darf publishen
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

  # TODO: Message Retention Period setzen
  # Hinweis: Variable message_retention_seconds verwenden
  # Dokumentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue
  message_retention_seconds = ___________________

  # TODO: Visibility Timeout setzen
  # Hinweis: Variable visibility_timeout_seconds verwenden
  visibility_timeout_seconds = ___________________

  # TODO: Tags hinzufügen (analog zu SNS Topic)
  tags = {
    # Deine Tags hier
  }
}

# SQS Queue Policy - erlaubt SNS das Senden von Messages
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  # TODO: Policy-Struktur erstellen
  # Hinweis: Siehe Console-Aufgabe Phase 3, Schritt 3
  #
  # Diese Policy muss:
  # 1. Version "2012-10-17" haben
  # 2. Statement mit Effect "Allow"
  # 3. Principal: { Service = "sns.amazonaws.com" }
  # 4. Action: "sqs:SendMessage"
  # 5. Resource: Queue ARN (aws_sqs_queue.main.arn)
  # 6. Condition: SourceArn muss Source Topic ARN sein
  #
  # Dokumentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy

  policy = jsonencode({
    Version = "___________________"
    Statement = [
      {
        Effect = "___________________"
        Principal = {
          # TODO: Welcher Service darf Messages senden?
          # Hinweis: Service = "sns.amazonaws.com"
        }
        Action   = "___________________"  # TODO: Welche Action? (sqs:SendMessage)
        Resource = ___________________    # TODO: Queue ARN (aws_sqs_queue.main.arn)
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = ___________________  # TODO: Source Topic ARN (aws_sns_topic.source.arn)
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
  topic_arn = ___________________  # TODO: SNS Topic ARN (aws_sns_topic.source.arn)
  protocol  = "sqs"
  endpoint  = ___________________  # TODO: SQS Queue ARN (aws_sqs_queue.main.arn)

  # Raw Message Delivery = false (SNS Envelope wird beibehalten)
  raw_message_delivery = false
}

# Dokumentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription

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
```

### Datei: `terraform.tfvars`

Setze deine persönlichen Werte:

```hcl
aws_region  = "eu-north-1"
environment = "dev"
```

---

## Phase 2: Code-Struktur verstehen

Die `main.tf` ist in **Abschnitte** unterteilt:

| Abschnitt | Zweck | Schwierigkeit |
|---|---|---|
| **Provider** | AWS Provider konfigurieren | Vorgegeben |
| **Variables** | Input-Parameter definieren | Vorgegeben |
| **SNS Topic** | Topic + Policy | Vollständig vorgegeben |
| **SQS Queue** | Queue + Policy | 50% vorgegeben, 50% selbst |
| **Subscriptions** | Verbindung erstellen | 70% vorgegeben, 30% Lücken |
| **Outputs** | Test-Informationen | Vorgegeben |

---

## Phase 3: Lücken ausfüllen - Schritt für Schritt

### Schritt 1: SQS Queue vervollständigen

**Suche nach:** `# SQS QUEUE` (Zeile 126)

**TODO 1:** Message Retention
```hcl
message_retention_seconds = var.message_retention_seconds
```

**TODO 2:** Visibility Timeout
```hcl
visibility_timeout_seconds = var.visibility_timeout_seconds
```

**TODO 3:** Tags
```hcl
tags = {
  Name        = "${var.environment}-sqs-queue"
  Environment = var.environment
  Purpose     = "Message Buffer"
}
```

📚 **Hilfe:** [AWS SQS Queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue)

---

### Schritt 2: SQS Queue Policy vervollständigen

**Suche nach:** `# SQS Queue Policy` (Zeile 145)

**Pseudo-Code zur Erinnerung:**
```
ERLAUBE dem Service "sns.amazonaws.com"
  die Action "sqs:SendMessage"
  auf Resource "Queue ARN"
  NUR WENN SourceArn = SNS Topic ARN
```

**TODO 1:** Version
```hcl
Version = "2012-10-17"
```

**TODO 2:** Effect
```hcl
Effect = "Allow"
```

**TODO 3:** Principal
```hcl
Principal = {
  Service = "sns.amazonaws.com"
}
```

**TODO 4:** Action
```hcl
Action = "sqs:SendMessage"
```

**TODO 5:** Resource
```hcl
Resource = aws_sqs_queue.main.arn
```

**TODO 6:** Condition SourceArn
```hcl
"aws:SourceArn" = aws_sns_topic.source.arn
```

📚 **Hilfe:** [AWS SQS Queue Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy)

---

### Schritt 3: Subscription vervollständigen

**Suche nach:** `# SUBSCRIPTIONS` (Zeile 187)

**TODO 1:** SNS Topic ARN
```hcl
topic_arn = aws_sns_topic.source.arn
```

**TODO 2:** SQS Queue ARN (Endpoint)
```hcl
endpoint = aws_sqs_queue.main.arn
```

**Wichtig:**
- `topic_arn` und `endpoint` sind unterschiedlich
- `raw_message_delivery = false` bleibt so (SNS Envelope wird beibehalten)

📚 **Hilfe:** [AWS SNS Subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription)

---

## Phase 4: Terraform Workflow

### Schritt 1: Initialisierung

```bash
cd 04-sns-sqs-sns
terraform init
```

**Erwartung:** Provider wird heruntergeladen, Backend initialisiert.

### Schritt 2: Validierung

```bash
terraform validate
```

**Erwartung:** "Success! The configuration is valid."

**Häufige Fehler:**
- Fehlende Klammern `}` oder `]`
- Tippfehler in Resource-Namen
- Vergessene Kommata

### Schritt 3: Formatierung (optional)

```bash
terraform fmt
```

Formatiert deinen Code automatisch.

### Schritt 4: Plan erstellen

```bash
terraform plan
```

**Erwartung:**
```
Plan: 5 to add, 0 to change, 0 to destroy.
```

**Die 5 Ressourcen:**
1. `aws_sns_topic.source`
2. `aws_sns_topic_policy.source`
3. `aws_sqs_queue.main`
4. `aws_sqs_queue_policy.main`
5. `aws_sns_topic_subscription.source_to_sqs`

**⚠️ Überprüfe den Plan:**
- Sind alle Namen korrekt (`dev-sns-sqs-...`)?
- Sind alle ARNs korrekt referenziert?
- Sind die Policies sinnvoll?

### Schritt 5: Apply ausführen

```bash
terraform apply
```

Gib `yes` ein, wenn der Plan korrekt aussieht.

**Erwartung:**
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

sns_topic_arn = "arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-topic"
sqs_queue_arn = "arn:aws:sqs:eu-north-1:123456789012:dev-sns-sqs-queue"
sqs_queue_url = "https://sqs.eu-north-1.amazonaws.com/123456789012/dev-sns-sqs-queue"
test_command_publish = "aws sns publish --topic-arn arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-topic --subject 'Test Message' --message 'Hello from Terraform!'"
test_command_receive = "aws sqs receive-message --queue-url https://sqs.eu-north-1.amazonaws.com/123456789012/dev-sns-sqs-queue"
```

---

## Phase 5: Testing

### Test 1: Message über AWS CLI publishen

Kopiere den Test-Command aus den Outputs:

```bash
terraform output -raw test_command_publish
```

Führe ihn aus:

```bash
aws sns publish --topic-arn arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-topic --subject 'Test Message' --message 'Hello from Terraform!'
```

**Erwartung:**
```json
{
    "MessageId": "12345-abcde-67890-fghij"
}
```

### Test 2: SQS Queue überprüfen

**Option A: AWS Console**
1. Navigiere zu SQS
2. Öffne die Queue `dev-sns-sqs-queue`
3. Klicke auf "Send and receive messages" → "Poll for messages"
4. Du solltest die Message im SNS-Format sehen

**Option B: AWS CLI**
```bash
terraform output -raw test_command_receive
```

oder direkt:

```bash
aws sqs receive-message --queue-url $(terraform output -raw sqs_queue_url)
```

**Erwartete Ausgabe:**
```json
{
  "Messages": [
    {
      "MessageId": "...",
      "Body": "{\"Type\":\"Notification\",\"Subject\":\"Test Message\",\"Message\":\"Hello from Terraform!\", ...}"
    }
  ]
}
```

---

## Checkliste - Terraform Implementation

- [ ] `main.tf` erstellt
- [ ] `terraform.tfvars` erstellt
- [ ] Alle TODOs in `main.tf` ausgefüllt
- [ ] `terraform init` erfolgreich
- [ ] `terraform validate` erfolgreich
- [ ] `terraform plan` zeigt 5 Ressourcen
- [ ] `terraform apply` erfolgreich
- [ ] Test 1: Message in SNS Topic published (CLI)
- [ ] Test 2: Message in SQS Queue gefunden

---

## Häufige Fehler und Lösungen

### Fehler 1: "Invalid reference" bei Policies

**Problem:** Terraform findet die Ressource nicht.

**Lösung:**
- Überprüfe Resource-Namen (z.B. `aws_sns_topic.source`)
- Stelle sicher, dass du `.arn` oder `.id` verwendest

**Beispiel:**
```hcl
# Falsch
Resource = aws_sqs_queue.main

# Richtig
Resource = aws_sqs_queue.main.arn
```

### Fehler 2: SQS empfängt keine Messages

**Problem:** Queue Policy fehlt oder ist falsch.

**Lösung:**
- Überprüfe `aws_sqs_queue_policy`
- Principal muss `{ Service = "sns.amazonaws.com" }` sein
- Condition muss auf SNS Topic ARN zeigen (`aws_sns_topic.source.arn`)

### Fehler 3: Syntax Error bei JSON Policy

**Problem:** Fehlende Kommata oder Klammern in der Policy.

**Lösung:**
- Überprüfe alle `{`, `}`, `[`, `]`
- Jedes Statement-Element braucht ein Komma (außer dem letzten)
- Nutze einen JSON-Validator online

---

## Best Practices - Was du gelernt hast

| Konzept | Bedeutung |
|---|---|
| **Single File Structure** | Alle Ressourcen in einer Datei (einfach für kleine Projekte) |
| **Variables** | Wiederverwendbare, anpassbare Konfiguration |
| **Outputs** | Wichtige Werte für Testing und weitere Automation |
| **Data Sources** | Dynamische Informationen wie Account ID abrufen |
| **Resource Dependencies** | Terraform erkennt automatisch die Reihenfolge (SNS → Queue → Subscription) |
| **Tags** | Alle Ressourcen taggen für Kostenmanagement und Organisation |
| **Naming Convention** | `${var.environment}-service-purpose` Pattern |
| **Policy as Code** | IAM Policies in Terraform mit `jsonencode()` |

---

## Cleanup - Ressourcen löschen

**Wichtig:** Vergiss nicht, die Ressourcen zu löschen, um Kosten zu vermeiden!

```bash
terraform destroy
```

Gib `yes` ein, um alle Ressourcen zu löschen.

**Erwartung:**
```
Destroy complete! Resources: 5 destroyed.
```

---

## Nächste Schritte

Nach dieser Aufgabe kannst du:
- [ ] Die Pipeline erweitern mit Lambda-Funktionen (automatische Queue-Verarbeitung)
- [ ] Dead-Letter Queues hinzufügen
- [ ] CloudWatch Alarms für Monitoring
- [ ] Multi-Environment Setup (dev, test, prod)
- [ ] Code in Module aufteilen für Wiederverwendbarkeit

**Gratulation! Du hast eine SNS-SQS Pipeline mit Terraform gebaut!** 🎉

---

## Bonus: Code-Qualität verbessern

Wenn du fertig bist und Zeit hast:

### 1. Locals verwenden
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "sns-sqs-demo"
    ManagedBy   = "Terraform"
  }
}

# Dann in Ressourcen:
tags = merge(local.common_tags, {
  Name = "${var.environment}-sns-topic"
})
```

### 2. Description zu Ressourcen hinzufügen
```hcl
resource "aws_sns_topic" "source" {
  name         = "${var.environment}-sns-sqs-topic"
  display_name = "SNS Source Topic"

  # Hilfreich für Dokumentation
  tags = {
    Name        = "${var.environment}-sns-topic"
    Environment = var.environment
    Purpose     = "Message Source"
    Description = "Receives initial messages for SNS-SQS pipeline"
  }
}
```

---
