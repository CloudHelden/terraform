# Übung 2: SNS Topic mit Email Subscription

**Dauer:** ~12 Minuten
**Schwierigkeit:** Anfänger

## Dokumentation
Nutze diese Dokumentation um die Aufgabe zu lösen:
- [Terraform AWS Provider Docs - SNS Topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)
- [Terraform AWS Provider Docs - SNS Topic Subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription)

## Lernziele
- ✅ SNS Topics verstehen
- ✅ Subscriptions erstellen
- ✅ Resource Dependencies (automatisch)
- ✅ Variables nutzen
- ✅ Grenzen von Terraform verstehen (manuelle Email-Bestätigung)

## Aufgabe
Erstelle ein SNS Topic und abonniere es mit deiner Email-Adresse auf Basis der Dokumentation oben.

## Schritte

1. **Email-Adresse anpassen:**
   Öffne `main.tf` und ändere die `default` Email-Adresse oder setze sie beim Apply:
   ```bash
   terraform apply -var="email_address=deine@email.com"
   ```

2. **Initialisiere und Apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Email-Bestätigung:**
   - Du bekommst eine Email von AWS
   - Klicke auf "Confirm subscription"
   - ⚠️ **Wichtig:** Terraform kann das NICHT automatisch machen!

4. **Teste das Topic:**
   In der AWS Console:
   - Gehe zu SNS → Topics
   - Wähle dein Topic
   - Klicke "Publish message"
   - Schreibe eine Test-Nachricht
   - Du solltest eine Email bekommen!

5. **Prüfe den State:**
   ```bash
   terraform show
   ```
   Schau dir an wie Terraform die Resources speichert.

6. **Aufräumen:**
   ```bash
   terraform destroy
   ```

## Konzepte erklärt

### Variable
```hcl
variable "email_address" {
  type    = string
  default = "test@example.com"
}
```
Macht Code wiederverwendbar.

### Resource Dependency
```hcl
topic_arn = aws_sns_topic.notifications.arn
```
Terraform weiß: Topic muss ZUERST erstellt werden, dann Subscription.

### ARN (Amazon Resource Name)
Eindeutige ID für AWS Resources:
```
arn:aws:sns:eu-central-1:123456789:terraform-uebung-notifications
```

## Wichtige Erkenntnis

Terraform erstellt die Subscription, aber **du musst die Email manuell bestätigen**.
Terraform kann nicht alles automatisieren - manchmal braucht es manuelle Schritte!

## Bonus-Aufgaben
- [ ] Füge eine zweite Email-Subscription hinzu
- [ ] Ändere `display_name` und apply erneut (beobachte was passiert)
- [ ] Füge eine SMS-Subscription hinzu (protocol = "sms", endpoint = "+49...")

## Lösung
Falls du nicht weiterkommst, schau in die Datei `solution.tf` für eine vollständige Lösung.
