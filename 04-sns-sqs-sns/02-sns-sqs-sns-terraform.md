# SNS → SQS → SNS Integration - Terraform Implementation

## Übersicht
In dieser Aufgabe setzt du die Konsolen-Aufgabe in Terraform-Code um. Du nutzt dabei dein Wissen aus den vorherigen Modulen (Variables, Outputs, IAM Permissions).

**Ziel:**
- Infrastructure as Code für SNS → SQS → SNS Pipeline
- Wiederholbare, versionierbare Deployments
- Best Practices für Terraform-Struktur

**Zeitrahmen:** ~90-120 Minuten

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

variable "email_address" {
  description = "Email-Adresse für SNS Notifications"
  type        = string
  # Kein Default - muss in terraform.tfvars gesetzt werden
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
# SNS SOURCE TOPIC (Geführt - 70% vorgegeben)
# ============================================================================

# SNS Topic für eingehende Messages
resource "aws_sns_topic" "source" {
  name         = "${var.environment}-sns-sqs-sns-source-topic"
  display_name = "SNS Source Topic"  # TODO: Kann auch anders benannt werden

  tags = {
    Name        = "${var.environment}-source-topic"
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
  name = "${var.environment}-sns-sqs-sns-queue"

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
# SNS TARGET TOPIC (Komplett selbstständig)
# ============================================================================

# TODO: Erstelle das Target SNS Topic komplett selbst!
# Kopiere die Struktur von aws_sns_topic.source oben und ändere:
# 1. Resource Name: "target" (statt "source")
# 2. Name: "${var.environment}-sns-sqs-sns-target-topic"
# 3. Display Name: z.B. "SNS Target Topic"
# 4. Tags Name: "${var.environment}-target-topic"
# 5. Tags Purpose: z.B. "Message Destination"

resource "aws_sns_topic" "target" {
  name         = "${var.environment}-sns-sqs-sns-target-topic"
  display_name = "___________________"  # TODO: Display Name eintragen

  tags = {
    Name        = "${var.environment}-target-topic"
    Environment = var.environment
    Purpose     = "___________________"  # TODO: Zweck beschreiben
  }
}

# TODO: Erstelle die Topic Policy für das Target Topic
# Kopiere aws_sns_topic_policy.source und ändere:
# 1. Resource Name: "target" (statt "source")
# 2. arn: aws_sns_topic.target.arn (statt .source)
# 3. Resource in Policy: aws_sns_topic.target.arn (statt .source)

resource "aws_sns_topic_policy" "target" {
  arn = aws_sns_topic.target.arn

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
        Resource = ___________________  # TODO: aws_sns_topic.target.arn (nicht .source!)
      }
    ]
  })
}

# ============================================================================
# SUBSCRIPTIONS
# ============================================================================

# Subscription 1: SNS Source Topic → SQS Queue
resource "aws_sns_topic_subscription" "source_to_sqs" {
  topic_arn = ___________________  # TODO: Source Topic ARN (aws_sns_topic.source.arn)
  protocol  = "sqs"
  endpoint  = ___________________  # TODO: SQS Queue ARN (aws_sqs_queue.main.arn)

  # Raw Message Delivery = false (SNS Envelope wird beibehalten)
  raw_message_delivery = false
}

# Subscription 2: SNS Target Topic → Email
resource "aws_sns_topic_subscription" "target_to_email" {
  topic_arn = ___________________  # TODO: Target Topic ARN (aws_sns_topic.target.arn)
  protocol  = "___________________"  # TODO: Protokoll für Email (Hinweis: "email")
  endpoint  = var.email_address
}

# Dokumentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription

# ============================================================================
# OUTPUTS
# ============================================================================

output "source_topic_arn" {
  description = "ARN des Source SNS Topics"
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

output "target_topic_arn" {
  description = "ARN des Target SNS Topics"
  value       = aws_sns_topic.target.arn
}

output "test_command_publish" {
  description = "AWS CLI Command zum Testen"
  value       = "aws sns publish --topic-arn ${aws_sns_topic.source.arn} --subject 'Test Message' --message 'Hello from Terraform!'"
}
```

### Datei: `terraform.tfvars`

Setze deine persönlichen Werte:

```hcl
aws_region    = "eu-north-1"
environment   = "dev"
email_address = "deine-email@example.com"  # WICHTIG: Deine echte Email eintragen!
```

---

## Phase 2: Code-Struktur verstehen

Die `main.tf` ist in **Abschnitte** unterteilt:

| Abschnitt | Zweck | Schwierigkeit |
|---|---|---|
| **Provider** | AWS Provider konfigurieren | Vorgegeben |
| **Variables** | Input-Parameter definieren | Vorgegeben |
| **SNS Source** | Erstes Topic + Policy | 70% vorgegeben, 30% Lücken |
| **SQS Queue** | Queue + Policy | 50% vorgegeben, 50% selbst |
| **SNS Target** | Zweites Topic + Policy | 50% vorgegeben, 50% selbst |
| **Subscriptions** | Verbindungen erstellen | 70% vorgegeben, 30% Lücken |
| **Outputs** | Test-Informationen | Vorgegeben |

---

## Phase 3: Lücken ausfüllen - Schritt für Schritt

### Schritt 1: SNS Source Topic vervollständigen

**Suche nach:** `# SNS SOURCE TOPIC` (Zeile ~92)

**TODO 1:** Display Name
```hcl
display_name = "SNS Source Topic"
```

**TODO 2:** Purpose Tag
```hcl
Purpose = "Message Source"
```

**TODO 3:** Principal AWS ARN (in der Policy)
```hcl
AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
```

**Erklärung:**
- `display_name`: Name, der in AWS Console angezeigt wird
- `Purpose` Tag: Hilft zur Dokumentation (wofür ist dieses Topic?)
- `arn:aws:iam::${data.aws_caller_identity.current.account_id}:root`: Erlaubt dem **Root User deines AWS Accounts**, in dieses Topic zu publishen

📚 **Hilfe:** [AWS SNS Topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)

---

### Schritt 2: SQS Queue vervollständigen

**Suche nach:** `# SQS QUEUE` (Zeile ~130)

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

### Schritt 3: SQS Queue Policy vervollständigen

**Suche nach:** `# SQS Queue Policy` (Zeile ~152)

**Pseudo-Code zur Erinnerung:**
```
ERLAUBE dem Service "sns.amazonaws.com"
  die Action "sqs:SendMessage"
  auf Resource "Queue ARN"
  NUR WENN SourceArn = Source Topic ARN
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

### Schritt 4: SNS Target Topic vervollständigen (50% selbst)

**Suche nach:** `# SNS TARGET TOPIC` (Zeile ~190)

**Hinweis:** Das Skeleton ist bereits vorgegeben. Du brauchst nur die TODOs ausfüllen.

**Was ist bereits gegeben:**
- `name` = `"${var.environment}-sns-sqs-sns-target-topic"` ✅
- `tags Name` = `"${var.environment}-target-topic"` ✅
- Topic Policy Struktur und Principal ✅

**Was du noch ausfüllen musst:**
- `display_name`: z.B. `"SNS Target Topic"`
- `Purpose` Tag: z.B. `"Message Destination"`
- `Resource` in der Policy: `aws_sns_topic.target.arn` (nicht `.source`!)

**Struktur-Skeleton:**
```hcl
resource "aws_sns_topic" "target" {
  name         = "${var.environment}-sns-sqs-sns-target-topic"
  display_name = ___________________  # TODO: z.B. "SNS Target Topic"

  tags = {
    Name        = "${var.environment}-target-topic"
    Environment = var.environment
    Purpose     = ___________________  # TODO: z.B. "Message Destination"
  }
}

resource "aws_sns_topic_policy" "target" {
  arn = aws_sns_topic.target.arn

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
        Resource = ___________________  # TODO: aws_sns_topic.target.arn (nicht .source!)
      }
    ]
  })
}
```

**Wichtige Unterschiede zu Source Topic:**
- `aws_sns_topic.target` (neue Resource)
- `aws_sns_topic_policy.target` (neue Policy Resource)
- `Resource = aws_sns_topic.target.arn` (zeigt auf **target**, nicht **source**)

⚠️ **Häufiger Fehler:** Wenn du `.source.arn` kopierst, funktioniert die Pipeline nicht korrekt!

---

### Schritt 5: Subscriptions vervollständigen

**Suche nach:** `# SUBSCRIPTIONS` (Zeile ~240)

**Hinweis:** Die Subscriptions sind teilweise vorgegeben. Du brauchst nur die ARNs und Protokolle eintragen.

**Subscription 1: SNS Source Topic → SQS Queue**

**TODO 1:** Source Topic ARN
```hcl
topic_arn = aws_sns_topic.source.arn
```

**TODO 2:** SQS Queue ARN (Endpoint)
```hcl
endpoint = aws_sqs_queue.main.arn
```

**Subscription 2: SNS Target Topic → Email**

**TODO 3:** Target Topic ARN
```hcl
topic_arn = aws_sns_topic.target.arn
```

**TODO 4:** Email-Protokoll
```hcl
protocol = "email"
```

**Wichtig:**
- `topic_arn` und `endpoint` sind unterschiedlich je nach Subscription
- `raw_message_delivery = false` bleibt so (SNS Envelope wird beibehalten)
- `endpoint` bei Email ist `var.email_address` (bereits vorgegeben)

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
Plan: 8 to add, 0 to change, 0 to destroy.
```

**Die 8 Ressourcen:**
1. `aws_sns_topic.source`
2. `aws_sns_topic_policy.source`
3. `aws_sqs_queue.main`
4. `aws_sqs_queue_policy.main`
5. `aws_sns_topic.target`
6. `aws_sns_topic_policy.target`
7. `aws_sns_topic_subscription.source_to_sqs`
8. `aws_sns_topic_subscription.target_to_email`

**⚠️ Überprüfe den Plan:**
- Sind alle Namen korrekt (`dev-sns-sqs-sns-...`)?
- Sind alle ARNs korrekt referenziert?
- Sind die Policies sinnvoll?

### Schritt 5: Apply ausführen

```bash
terraform apply
```

Gib `yes` ein, wenn der Plan korrekt aussieht.

**Erwartung:**
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

source_topic_arn = "arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-sns-source-topic"
sqs_queue_arn = "arn:aws:sqs:eu-north-1:123456789012:dev-sns-sqs-sns-queue"
sqs_queue_url = "https://sqs.eu-north-1.amazonaws.com/123456789012/dev-sns-sqs-sns-queue"
target_topic_arn = "arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-sns-target-topic"
test_command_publish = "aws sns publish --topic-arn arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-sns-source-topic --subject 'Test Message' --message 'Hello from Terraform!'"
```

### Schritt 6: Email-Subscription bestätigen

1. Öffne dein Email-Postfach
2. Suche nach "AWS Notification - Subscription Confirmation"
3. Klicke auf den Bestätigungslink
4. Die Email-Subscription ist jetzt aktiv

---

## Phase 5: Testing

### Test 1: Message über AWS CLI publishen

Kopiere den Test-Command aus den Outputs:

```bash
terraform output -raw test_command_publish
```

Führe ihn aus:

```bash
aws sns publish --topic-arn arn:aws:sns:eu-north-1:123456789012:dev-sns-sqs-sns-source-topic --subject 'Test Message' --message 'Hello from Terraform!'
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
2. Öffne die Queue `dev-sns-sqs-sns-queue`
3. Klicke auf "Send and receive messages" → "Poll for messages"
4. Du solltest die Message im SNS-Format sehen

**Option B: AWS CLI**
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

### Test 3: Message in Target Topic publishen

Simuliere die Queue-Verarbeitung:

```bash
aws sns publish \
  --topic-arn $(terraform output -raw target_topic_arn) \
  --subject 'Processed Message' \
  --message 'Diese Message wurde durch die Pipeline verarbeitet!'
```

### Test 4: Email empfangen

Überprüfe dein Email-Postfach - du solltest die Message vom Target Topic erhalten.

---

## Checkliste - Terraform Implementation

- [ ] `main.tf` erstellt
- [ ] `terraform.tfvars` mit deiner Email erstellt
- [ ] Alle TODOs in `main.tf` ausgefüllt
- [ ] SNS Target Topic komplett selbst geschrieben
- [ ] `terraform init` erfolgreich
- [ ] `terraform validate` erfolgreich
- [ ] `terraform plan` zeigt 8 Ressourcen
- [ ] `terraform apply` erfolgreich
- [ ] Email-Subscription bestätigt
- [ ] Test 1: Message in Source Topic published (CLI)
- [ ] Test 2: Message in SQS Queue gefunden
- [ ] Test 3: Message in Target Topic published (CLI)
- [ ] Test 4: Email empfangen

---

## Häufige Fehler und Lösungen

### Fehler 1: "Error: Missing required argument"

**Problem:** Variable `email_address` nicht in `terraform.tfvars` gesetzt.

**Lösung:**
```hcl
# In terraform.tfvars
email_address = "deine-email@example.com"
```

### Fehler 2: "Invalid reference" bei Policies

**Problem:** Terraform findet die Ressource nicht.

**Lösung:**
- Überprüfe Resource-Namen (z.B. `aws_sns_topic.source` vs. `aws_sns_topic.target`)
- Stelle sicher, dass du `.arn` oder `.id` verwendest

**Beispiel:**
```hcl
# Falsch
Resource = aws_sqs_queue.main

# Richtig
Resource = aws_sqs_queue.main.arn
```

### Fehler 3: SQS empfängt keine Messages

**Problem:** Queue Policy fehlt oder ist falsch.

**Lösung:**
- Überprüfe `aws_sqs_queue_policy`
- Principal muss `{ Service = "sns.amazonaws.com" }` sein
- Condition muss auf Source Topic ARN zeigen (`aws_sns_topic.source.arn`)

### Fehler 4: Email-Subscription bleibt "Pending"

**Problem:** Email nicht bestätigt.

**Lösung:**
- Überprüfe Spam-Ordner
- Subscription manuell in Console bestätigen
- Neue Email-Adresse in `terraform.tfvars` eintragen und `terraform apply` erneut ausführen

### Fehler 5: "Cycle Error" in Terraform

**Problem:** Ressourcen referenzieren sich gegenseitig.

**Lösung:**
- Stelle sicher, dass SNS Source und Target **verschiedene Ressourcen** sind
- Keine Subscription von Target Topic zurück zu Source Topic

### Fehler 6: Syntax Error bei JSON Policy

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
| **Resource Dependencies** | Terraform erkennt automatisch die Reihenfolge (Source → Queue → Target) |
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
Destroy complete! Resources: 8 destroyed.
```

---

## Nächste Schritte

Nach dieser Aufgabe kannst du:
- [ ] Die Pipeline erweitern mit Lambda-Funktionen (automatische Queue-Verarbeitung)
- [ ] Dead-Letter Queues hinzufügen
- [ ] CloudWatch Alarms für Monitoring
- [ ] Multi-Environment Setup (dev, test, prod)
- [ ] Code in Module aufteilen für Wiederverwendbarkeit

**Gratulation! Du hast eine komplette SNS-SQS-SNS Pipeline mit Terraform gebaut!** 🎉

---

## Bonus: Code-Qualität verbessern

Wenn du fertig bist und Zeit hast:

### 1. Locals verwenden
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "sns-sqs-sns-demo"
    ManagedBy   = "Terraform"
  }
}

# Dann in Ressourcen:
tags = merge(local.common_tags, {
  Name = "${var.environment}-source-topic"
})
```

### 2. Validation Rules hinzufügen
```hcl
variable "email_address" {
  description = "Email-Adresse für SNS Notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_address))
    error_message = "Bitte gib eine gültige Email-Adresse an."
  }
}
```

### 3. Description zu Ressourcen hinzufügen
```hcl
resource "aws_sns_topic" "source" {
  name         = "${var.environment}-sns-sqs-sns-source-topic"
  display_name = "SNS Source Topic"

  # Hilfreich für Dokumentation
  tags = {
    Name        = "${var.environment}-source-topic"
    Environment = var.environment
    Purpose     = "Message Source"
    Description = "Receives initial messages for SNS-SQS-SNS pipeline"
  }
}
```
