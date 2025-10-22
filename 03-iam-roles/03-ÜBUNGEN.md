# Übungen: IAM Roles

## Übung 1: Lambda und DynamoDB deployieren

1. Stelle sicher, dass folgende Dateien im gleichen Ordner sind:
   - `03-main.tf`
   - `lambda.py`
   - `terraform.tfvars`

2. Initialisiere und deploye:
```bash
terraform init
terraform plan
terraform apply
```

3. Schau dir die erstellten Ressourcen an:
```bash
terraform output
```

**Was wird erstellt?**
- ✅ IAM Role für Lambda
- ✅ Permission Policy für DynamoDB
- ✅ DynamoDB Tabelle
- ✅ Lambda Function

---

## Übung 2: Lambda testen und schauen ob DynamoDB funktioniert

**Aufgabe:** Teste die Lambda Function mit der DynamoDB.

### Methode 1: AWS Lambda Console (GUI)

1. In AWS Console gehen: Services → Lambda
2. Klick auf die `my-lambda` Function
3. Klick auf "Test" oben rechts
4. Teste mit diesem Event:
```json
{
  "id": "test-123",
  "name": "Mein Test Item"
}
```

5. Klick "Invoke"
6. Schau das Ergebnis - Lambda schreibt und liest jetzt von DynamoDB!

**Expected Output:**
```json
{
  "statusCode": 200,
  "body": "{\"message\":\"Erfolgreich!\",\"item\":{\"id\":\"test-123\",\"name\":\"Mein Test Item\",\"timestamp\":\"2025-10-21T12:01:56.544991\"}}"
}
```

### Methode 2: AWS CLI (Command Line)

Wenn du lieber über die CLI testen möchtest:

```bash
# Test mit Payload
aws lambda invoke \
  --function-name my-lambda \
  --region eu-north-1 \
  --cli-binary-format raw-in-base64-out \
  --payload '{"id": "test-123", "name": "Mein Test Item"}' \
  /tmp/response.json

# Response anzeigen
cat /tmp/response.json

# Oder nur das body anzeigen (formatiert)
jq '.body | fromjson' /tmp/response.json
```

### Methode 3: DynamoDB Daten prüfen

Nach dem Test kannst du schauen, ob die Daten in DynamoDB gespeichert wurden:

**In der AWS Console:**
1. Services → DynamoDB
2. Tables → `my-table`
3. Klick auf "Explore table items"
4. Du solltest dein Test-Item sehen!

**Oder via CLI:**
```bash
aws dynamodb scan \
  --table-name my-table \
  --region eu-north-1
```

**Expected Output:** Deine Items sollten hier auftauchen mit `id`, `name` und `timestamp`

---

## Checkliste

- [ ] Übung 1: Lambda und DynamoDB mit IAM Role deployieren
- [ ] Übung 2: Lambda Function testen (GUI oder CLI)
- [ ] Übung 3: DynamoDB Daten prüfen
- [ ] Bonus: Mehrere Test-Events mit verschiedenen IDs und Namen testen
