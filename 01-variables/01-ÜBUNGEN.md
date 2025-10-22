# Übungen: Input Variables

## Übung 1: Variablen ändern und Unterschiede sehen

1. Erstelle eine `terraform.tfvars` Datei:
```hcl
aws_region      = "eu-north-1"
instance_name   = "my-webserver"
instance_count  = 1
enable_public_ip = true
allowed_ssh_cidrs = ["0.0.0.0/0"]
instance_tags = {
  Environment = "development"
  Team        = "DevOps"
}
instance_config = {
  instance_type = "t3.micro"
  volume_size   = 20
}
```

2. Führe aus:
```bash
terraform init
terraform plan
```

3. Ändere jetzt in `terraform.tfvars`:
```hcl
instance_count  = 3           # Statt 1
instance_name   = "prod-web"  # Neuer Name
enable_public_ip = false      # Keine öffentliche IP
```

4. Führe wieder aus und beobachte die Unterschiede:
```bash
terraform plan
```

**Was sollte sich ändern?** 3 Instanzen statt 1, andere Namen, keine öffentliche IPs

---

## Übung 2: Neue STRING Variable hinzufügen

**Was ist Validation?**
Validierung prüft, ob der eingegebene Wert erlaubt ist. Mit `validation` kannst du sicherstellen, dass nur bestimmte Werte akzeptiert werden. Wenn der Wert nicht passt, gibt Terraform einen Fehler aus und verhindert das Deployment. So vermeidest du Fehler durch falsche Eingaben.

**Aufgabe:** Füge eine Variable `environment` mit Validierung hinzu.

1. Füge in `01-main.tf` nach `instance_name` hinzu:
```hcl
variable "environment" {
  type        = string
  default     = "development"
  description = "development, staging oder production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Nur development, staging oder production erlaubt!"
  }
}
```

2. Nutze die Variable in den Tags (bei `instance_tags`):
```hcl
tags = merge(var.instance_tags, { Environment = var.environment })
```

3. Füge in `terraform.tfvars` hinzu:
```hcl
environment = "development"
```

4. Teste:
```bash
terraform plan
terraform plan -var="environment=production"
terraform plan -var="environment=invalid"  # Das sollte Error geben!
```

---

## Übung 3: LIST Variable für HTTP CIDR Blöcke

**Aufgabe:** Erstelle zusätzliche Liste für HTTP/HTTPS Zugriff.

1. Füge in `01-main.tf` nach `allowed_ssh_cidrs` hinzu:
```hcl
variable "allowed_http_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR Blöcke für HTTP/HTTPS"
}
```

2. Füge HTTP/HTTPS Rules zur Security Group hinzu:
```hcl
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidrs
}

ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidrs
}
```

3. In `terraform.tfvars`:
```hcl
allowed_ssh_cidrs = ["10.0.0.0/8"]
allowed_http_cidrs = ["0.0.0.0/0"]
```

4. Teste:
```bash
terraform plan
```

---

## Checkliste

- [ ] Übung 1: terraform.tfvars ändern und terraform plan testen
- [ ] Übung 2: STRING Variable mit Validierung hinzufügen
- [ ] Übung 3: LIST Variable für HTTP CIDR Blöcke erstellen

