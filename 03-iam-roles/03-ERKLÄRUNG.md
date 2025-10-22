# IAM Roles - Rollen mit Terraform erstellen

## 🎓 Was lernst du in dieser Übung?

1. **Data Sources nutzen** - `aws_iam_policy_document` um IAM Policies zu schreiben
2. **Ressourcen verbinden** - Role an Lambda hängen mit `role = aws_iam_role.xxx.arn`
3. **Sicherheit mit Terraform** - Least Privilege Prinzip umsetzen
4. **Attribute References** - ARNs und IDs zwischen Ressourcen weitergeben
5. **Policy Logic verstehen** - Was darf wer wo machen?

---

## Der Workflow: Trust Policy → Role → Permission → Ressource

```
1. Trust Policy definieren
   ↓
   "Wer darf diese Rolle benutzen?"
   (Antwort: Der Lambda Service)
   ↓
2. IAM Role erstellen
   ↓
   "Erstelle die Rolle mit der Trust Policy"
   ↓
3. Permission Policy definieren
   ↓
   "Was darf die Rolle machen?"
   (Antwort: DynamoDB GetItem, PutItem, etc.)
   ↓
4. Permission Policy anhängen
   ↓
   "Hänge die Berechtigungen an die Rolle"
   ↓
5. Ressource mit Rolle verbinden
   ↓
   "Lambda bekommt diese Rolle"
   (Lambda kann jetzt auf DynamoDB zugreifen!)
```

---

## Schritt-für-Schritt mit Terraform

### 1. Trust Policy - Wer nutzt die Rolle?
```hcl
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]  # Lambda Service
    }
    action = "sts:AssumeRole"  # "Annehmen" der Rolle
  }
}
```
**Bedeutung:** Der Lambda Service darf diese Rolle benutzen.

### 2. IAM Role erstellen
```hcl
resource "aws_iam_role" "lambda_role" {
  name               = "my-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
```
**Bedeutung:** Erstelle die Rolle mit der Trust Policy.

### 3. Permission Policy - Was darf sie machen?
```hcl
data "aws_iam_policy_document" "lambda_dynamodb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",    # Item lesen
      "dynamodb:PutItem",    # Item schreiben
      "dynamodb:Query",      # Abfragen
      "dynamodb:Scan"        # Alles durchsuchen
    ]
    resources = [aws_dynamodb_table.my_table.arn]  # Nur diese Tabelle
  }
}
```
**Bedeutung:** Erlaube diese DynamoDB Operationen.

### 4. Policy an Rolle anhängen
```hcl
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "lambda-dynamodb-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_dynamodb_policy.json
}
```
**Bedeutung:** Hänge die Berechtigungen an die Rolle.

## Lambda Function mit Rolle verbinden
```hcl
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-lambda"
  role          = aws_iam_role.lambda_role.arn  # Rolle zuweisen!
  handler       = "lambda.handler"
  runtime       = "nodejs.18.x"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.my_table.name
    }
  }
}
```
**Wichtig:** `role` = ARN der erstellten Rolle


## Zusammenfassung

| Teil | Code | Bedeutung |
|------|------|-----------|
| **Trust Policy** | `aws_iam_policy_document` + `assume_role_policy` | Wer nutzt die Rolle |
| **Role** | `aws_iam_role` | Die Rolle erstellen |
| **Permission Policy** | `aws_iam_policy_document` | Welche Berechtigungen |
| **Anhängen** | `aws_iam_role_policy` | Policy zur Rolle hinzufügen |
| **Verbinden** | `role = aws_iam_role.xxx.arn` | Ressource bekommt die Rolle |
