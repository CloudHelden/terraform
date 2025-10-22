# Übung 3: SQS Queue mit Dead Letter Queue

**Dauer:** ~15 Minuten
**Schwierigkeit:** Anfänger bis Mittel

## Dokumentation
Nutze diese Dokumentation um die Aufgabe zu lösen:
- [Terraform AWS Provider Docs - SQS Queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue)
- [Terraform Language - Functions - jsonencode](https://developer.hashicorp.com/terraform/language/functions/jsonencode)
- [AWS SQS Dead Letter Queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html)

## Lernziele
- ✅ Mehrere verwandte Resources erstellen
- ✅ `jsonencode()` für komplexe Attribute
- ✅ Resource References zwischen Queues
- ✅ ARN vs. URL verstehen
- ✅ Dead Letter Queue Konzept

## Aufgabe
Erstelle zwei SQS Queues: Eine Haupt-Queue und eine Dead Letter Queue (DLQ) auf Basis der Dokumentation oben.
Messages die 3x nicht verarbeitet werden können, landen automatisch in der DLQ.

## Schritte

1. **Initialisiere und Apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Schau dir die Outputs an:**
   ```bash
   terraform output
   ```
   Beachte: Jede Queue hat eine URL UND eine ARN!

3. **Teste in AWS Console:**
   - Gehe zu SQS in der AWS Console
   - Finde beide Queues
   - Klicke auf die Main Queue
   - Unter "Dead-letter queue" solltest du die DLQ sehen

4. **Teste das Verhalten (optional):**
   - Sende eine Message an die Main Queue
   - Empfange sie 3x OHNE zu löschen (über Console)
   - Nach dem 3. Mal landet sie in der DLQ!

5. **Prüfe den State:**
   ```bash
   terraform state list
   terraform state show aws_sqs_queue.main
   ```

6. **Aufräumen:**
   ```bash
   terraform destroy
   ```

## Konzepte erklärt

### Dead Letter Queue (DLQ)
Eine "Auffang"-Queue für Messages die nicht verarbeitet werden können.
Verhindert dass fehlerhafte Messages verloren gehen oder ewig blockieren.

### jsonencode() - Warum brauchen wir das?

AWS erwartet für `redrive_policy` einen **JSON-String** (nicht ein Objekt!).

**Ohne jsonencode() würde das SO aussehen (funktioniert NICHT):**
```hcl
redrive_policy = {
  deadLetterTargetArn = "arn:aws:sqs:..."
  maxReceiveCount     = 3
}
# ❌ Fehler: AWS will einen String, kein Objekt!
```

**Mit jsonencode() - SO funktioniert es:**
```hcl
redrive_policy = jsonencode({
  deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
  maxReceiveCount     = 3
})
# ✅ Terraform konvertiert das zu: "{\"deadLetterTargetArn\":\"arn:aws:sqs:...\",\"maxReceiveCount\":3}"
```

**Was macht jsonencode()?**
- Nimmt ein Terraform-Objekt (Map)
- Konvertiert es zu einem JSON-String
- AWS kann damit arbeiten

**Analogie:** Wie ein Übersetzer - Terraform spricht HCL, AWS versteht nur JSON für Policies.

### ARN vs. URL
- **ARN:** Eindeutige ID für AWS-intern
  ```
  arn:aws:sqs:eu-central-1:123456789:terraform-uebung-dlq
  ```
- **URL:** HTTP-Endpoint zum Senden/Empfangen
  ```
  https://sqs.eu-central-1.amazonaws.com/123456789/terraform-uebung-dlq
  ```

### Resource Reference
```hcl
aws_sqs_queue.dead_letter.arn
#    ↑           ↑           ↑
# Resource   Local Name   Attribute
```

Terraform weiß: DLQ muss ZUERST erstellt werden!

## Wie funktioniert's?

1. Message kommt in Main Queue
2. Consumer empfängt Message (wird unsichtbar für andere)
3. Verarbeitung schlägt fehl → Consumer löscht Message NICHT
4. Nach `visibility_timeout` wird Message wieder sichtbar
5. Nach 3 erfolglosen Versuchen (`maxReceiveCount`) → ab in DLQ!

## Bonus-Aufgaben
- [ ] Ändere `maxReceiveCount` auf 5
- [ ] Füge `delay_seconds = 10` zur Main Queue hinzu
- [ ] Erstelle eine zweite Main Queue die die gleiche DLQ nutzt
- [ ] Füge einen CloudWatch Alarm hinzu wenn DLQ nicht leer ist

## Lösung
Falls du nicht weiterkommst, schau in die Datei `solution.tf` für eine vollständige Lösung.
