# Übung 1: S3 Bucket mit Versioning

**Dauer:** ~10 Minuten

## Dokumentation
Nutze diese Dokumentation um die Aufgabe zu lösen:
- [Terraform AWS Provider Docs - S3 Bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Terraform AWS Provider Docs - S3 Bucket Versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)
- [Terraform Random Provider - random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id)

## Lernziele
- ✅ Erste Terraform Resource erstellen
- ✅ Attribute und verschachtelte Blocks verstehen
- ✅ Tags für Resource Management
- ✅ Outputs nutzen
- ✅ Terraform Workflow (init, plan, apply, destroy)

## Aufgabe
Erstelle einen S3 Bucket mit aktiviertem Versioning auf Basis der Dokumentation oben.

## Schritte

1. **Initialisiere Terraform:**
   ```bash
   terraform init
   ```

2. **Plane die Änderungen:**
   ```bash
   terraform plan
   ```
   → Schau dir an was Terraform erstellen wird!

3. **Erstelle die Resources:**
   ```bash
   terraform apply
   ```
   → Tippe `yes` zum Bestätigen

4. **Prüfe die Outputs:**
   Die Bucket-URL wird ausgegeben.

5. **Teste in AWS Console:**
   - Gehe zu S3 in der AWS Console
   - Finde deinen Bucket
   - Prüfe unter "Properties" → "Bucket Versioning" ist "Enabled"

6. **Aufräumen:**
   ```bash
   terraform destroy
   ```

## Konzepte erklärt

### Resource Block
```hcl
resource "aws_s3_bucket" "main" {
  # "aws_s3_bucket" = Resource Type
  # "main" = Local Name (für Terraform)
}
```

### Attribute Reference
```hcl
aws_s3_bucket.main.id   # Referenziert den Bucket Namen
```

### Tags
```hcl
tags = {
  Name = "Wert"
}
```
Tags helfen beim Organisieren von AWS Resources.

### Random Provider für eindeutige Namen
S3 Bucket-Namen müssen **global eindeutig** sein (weltweit!).
```hcl
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket = "terraform-uebung-${random_id.suffix.hex}"
  #                           ↑ String Interpolation
}
```
- `random_id` generiert eine zufällige ID (z.B. "a3f7b9c2")
- `${...}` = String Interpolation (fügt Werte in Strings ein)
- Ergebnis: `terraform-uebung-a3f7b9c2` (garantiert eindeutig)

## Bonus-Aufgaben
- [ ] Füge ein weiteres Tag hinzu
- [ ] Ändere die Region in `provider.tf` zu `us-east-1`
- [ ] Füge `force_destroy = true` zum Bucket hinzu (erlaubt destroy auch wenn Objekte drin sind)

## Lösung
Falls du nicht weiterkommst, schau in die Datei `solution.tf` für eine vollständige Lösung.
