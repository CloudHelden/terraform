# Outputs - Ergebnisse ausgeben

## Grundkonzept
Outputs sind wie **Return-Werte** einer Funktion. Sie zeigen wichtige Ergebnisse nach `terraform apply` an und machen Werte für andere Terraform-Konfigurationen zugänglich.

## Output Types

### 1. STRING Output - Einzelne Werte
```hcl
output "security_group_id" {
  description = "ID der Security Group"
  value       = aws_security_group.web.id
}
```
**Nutze für:** IDs, Namen, einzelne Attribute

### 2. LIST Output - Array (Splat Syntax)
```hcl
output "instance_ids" {
  description = "IDs aller erstellten Instanzen"
  value       = aws_instance.web[*].id
}
```
**Nutze für:** Mehrere Werte mit `[*]` (splat syntax)

### 3. MAP Output - Key-Value Paare
```hcl
output "instance_details" {
  description = "Details zu den Instanzen"
  value = {
    instance_count = var.instance_count
    instance_type  = "t3.micro"
  }
}
```
**Nutze für:** Zusammenhängende Informationen

### 4. SENSITIVE Output - Sensitive Daten (SSH Key Pair)
```hcl
output "ec2_private_key" {
  description = "Private Key für SSH Zugriff"
  value       = aws_key_pair.deployer.private_key_pem
  sensitive   = true  # Wird nicht angezeigt!
}
```
**Nutze für:** Passwörter, Private Keys, sensitive Informationen

**So wird es angezeigt:**
```bash
$ terraform apply

Outputs:

ec2_private_key = <sensitive>
```

Der aktuelle Wert bleibt verborgen (auch nicht in Logs!). Um den Wert trotzdem zu sehen:
```bash
terraform output ec2_private_key
```

**Warum sensitive?** Private Keys, Passwörter und Secrets sollten nicht in der Terraform-Ausgabe oder in Logs sichtbar sein, um Sicherheitsrisiken zu vermeiden.

## Attribute References - Welche Werte kann ich ausgeben?

Jede AWS-Ressource hat bestimmte Attribute, die du ausgeben kannst:

```hcl
# Beispiele aus aws_instance
aws_instance.web.id              # Instance ID
aws_instance.web.public_ip       # Öffentliche IP
aws_instance.web.private_ip      # Private IP
aws_instance.web.instance_type   # Instance Type
aws_instance.web.arn             # Amazon Resource Name

# Beispiele aus aws_security_group
aws_security_group.web.id        # Security Group ID
aws_security_group.web.name      # Name
aws_security_group.web.vpc_id    # VPC ID
```

[Alle Attribute findest du in der AWS Provider Dokumentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Splat Syntax - Mehrere Werte aus Arrays (für später)

Mit `[*]` kannst du alle Werte aus einem Array holen:
```hcl
aws_instance.web[*].id           # Alle Instance IDs
aws_instance.web[*].public_ip    # Alle Public IPs
```

**Hinweis:** Anfänger brauchen das nicht zu verstehen. Du brauchst es nur wenn du `count` nutzt und alle Werte ausgeben willst.

## Output nach terraform apply

Nach `terraform apply` sieht man die Outputs:

```
Outputs:

security_group_id = "sg-1234567890abcdef0"
instance_ids = [
  "i-0123456789abcdef0",
  "i-0123456789abcdef1",
  "i-0123456789abcdef2",
]
deployment_summary = {
  instances = {
    count = 3
    ids   = [
      "i-0123456789abcdef0",
      "i-0123456789abcdef1",
      "i-0123456789abcdef2",
    ]
  }
  security_group = {
    id   = "sg-1234567890abcdef0"
    name = "my-server-sg"
  }
}
```

## Outputs abrufen (nach Deploy)

```bash
# Alle Outputs anzeigen
terraform output

# Einzelnen Output abrufen
terraform output security_group_id

# Im JSON Format (z.B. für Scripts)
terraform output -json

# Spezifischen Output im JSON
terraform output -json instance_ids
```

## Wichtige Begriffe

| Begriff | Bedeutung |
|---------|-----------|
| `description` | Dokumentation des Outputs |
| `value` | Der auszugebende Wert |
| `sensitive` | true = wird in Logs nicht angezeigt |
| `[*]` | Splat Syntax - alle Werte aus Array |
| `depends_on` | Explizite Abhängigkeit (optional) |

## Wann brauchst du Outputs?

✅ IDs weitergeben an andere Projekte
✅ Mit Scripts arbeiten (terraform output -json)
✅ Team-Informationen anzeigen
✅ Sensitive Daten kennzeichnen
✅ Dokumentation automatisieren
