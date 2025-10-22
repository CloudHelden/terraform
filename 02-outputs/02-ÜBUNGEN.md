# Übungen: Outputs

## Übung 1: Outputs anschauen und verstehen

1. Verwende die `02-main.tf` Datei:
```bash
terraform init
terraform plan
terraform apply
```

2. Schau dir alle Outputs an:
```bash
terraform output
```

3. Einzelne Outputs abrufen:
```bash
terraform output security_group_id
terraform output instance_ids
terraform output deployment_summary
```

4. Im JSON Format ausgeben (für Scripts):
```bash
terraform output -json
terraform output -json instance_ids
```

**Was solltest du sehen?** Die Werte der erstellten AWS-Ressourcen (IDs, IPs, Namen)

---

## Übung 2: Neue STRING Outputs hinzufügen

**Was ist ein Output?**
Ein Output gibt das Ergebnis des Deployments aus. Nach `terraform apply` zeigt Terraform deine definierten Outputs an. Das ist wichtig um IDs und andere Informationen zu sehen, die du später brauchst.

**Aufgabe:** Füge neue Outputs für einzelne Instance-Details hinzu.

1. Füge in `02-main.tf` nach dem `instance_public_ips` Output hinzu:
```hcl
output "first_instance_id" {
  description = "ID der ersten Instanz"
  value       = aws_instance.web[0].id
}

output "first_instance_ip" {
  description = "Öffentliche IP der ersten Instanz"
  value       = aws_instance.web[0].public_ip
}
```

2. Teste:
```bash
terraform plan
terraform apply
terraform output
```

3. Rufe einzelne Outputs ab:
```bash
terraform output first_instance_id
terraform output first_instance_ip
```

---

## Übung 3: LIST Output mit allen Private IPs

**Aufgabe:** Erstelle einen Output für alle privaten IP Adressen.

1. Füge nach dem `instance_public_ips` Output ein:
```hcl
output "instance_private_ips" {
  description = "Private IP Adressen aller Instanzen"
  value       = aws_instance.web[*].private_ip
}
```

2. Ändere die `terraform.tfvars`:
```hcl
instance_count = 3
```

3. Teste:
```bash
terraform plan
terraform apply
terraform output instance_private_ips
```

**Was solltest du sehen?** Ein Array mit 3 privaten IP Adressen
