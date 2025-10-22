# Input Variables & Variable Types

## Warum brauchen wir Variablen?

### Konkrete Anwendungszwecke:

**1. Verschiedene Umgebungen mit gleichen Code**
```
Scenario: Dein Code soll dev, staging UND production aufbauen

❌ FALSCH - Code duplizieren:
   - dev-main.tf
   - staging-main.tf
   - prod-main.tf
   (3 fast identische Dateien → Fehleranfällig!)

✅ RICHTIG - Eine Datei + Variablen:
   - 01-main.tf (gleich für alle)
   - dev.tfvars (Werte für dev)
   - staging.tfvars (Werte für staging)
   - prod.tfvars (Werte für prod)
```

**2. Gleiche Infrastruktur, unterschiedliche Konfigurationen**
```
Beispiel: EC2 Instance mit Variablen
- dev: 1x t3.micro (billig)
- prod: 3x t3.large (teuer, aber robust)

Gleicher Code, unterschiedliche Werte!
```

**3. Team-Zusammenarbeit**
```
Developer 1 arbeitet an dev Umgebung
Developer 2 arbeitet an prod Umgebung
→ Gleicher Code, unterschiedliche tfvars Files
→ Keine Konflikte!
```

---

## Warum tfvars Dateien?

### Das Problem ohne tfvars (Hardcoding):
```hcl
# ❌ FALSCH - Werte hardcodiert in main.tf
variable "instance_count" {
  default = 1  # Fest für dev
}
variable "instance_type" {
  default = "t3.micro"  # Fest für dev
}
```

**Probleme:**
- ❌ Code muss geändert werden für prod
- ❌ Fehlerquelle! (Vergessen umzuschalten)
- ❌ Git History zeigt alle Geheimnisse
- ❌ Nicht wiederverwendbar

---

### Die Lösung mit tfvars (Trennung):
```hcl
# ✅ RICHTIG - Code und Konfiguration getrennt

# 01-main.tf (Code - gleich für alle!)
variable "instance_count" {
  type = number
}
variable "instance_type" {
  type = string
}

# dev.tfvars (Dev Werte)
instance_count = 1
instance_type  = "t3.micro"

# prod.tfvars (Prod Werte)
instance_count = 3
instance_type  = "t3.large"
```

**Vorteile:**
- ✅ Code bleibt gleich (DRY Prinzip)
- ✅ Geheimnisse (API Keys, etc.) nicht im Code
- ✅ Verschiedene Umgebungen = verschiedene tfvars
- ✅ Team kann collaboraten ohne Konflikte

---

## Grundkonzept
Input Variables sind wie **Funktionsparameter** - sie machen Terraform Code flexibel und wiederverwendbar, ohne den Code zu ändern.

## Die 2 wichtigsten Variable Types

### 1. STRING - Textwerte
```hcl
variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "instance_name" {
  type    = string
  default = "my-server"
}
```

**Praktische Beispiele:**
- AWS Region: `"eu-north-1"`
- Ressourcen-Namen: `"my-webserver"`
- Umgebung: `"production"`
- URLs: `"https://example.com"`

**Wann nutzen?** Überall wo du Text brauchst: Namen, Beschreibungen, Identifikatoren

---

### 2. NUMBER - Zahlen
```hcl
variable "instance_count" {
  type    = number
  default = 1
}

variable "port" {
  type    = number
  default = 8080
}
```

**Praktische Beispiele:**
- Anzahl Instanzen: `3`
- Port-Nummern: `22`, `80`, `443`
- Speichergröße: `20`
- Timeout in Sekunden: `60`

**Wann nutzen?** Überall wo du Zahlen brauchst: Anzahl, Ports, Größen

---

## Weitere Types (zur Info)

Diese Types sind auch verfügbar, werden aber später wichtig:

| Type | Beispiel | Wann |
|------|----------|------|
| **BOOL** | `true` / `false` | Features ein/ausschalten |
| **LIST** | `["10.0.0.0/8", "192.168.1.0/24"]` | Mehrere Werte gleichen Typs |
| **MAP** | `{ Environment = "dev", Team = "DevOps" }` | Key-Value Paare (Tags) |
| **OBJECT** | `{ type = "t3.micro", size = 20 }` | Komplexe verschachtelte Struktur |

## So nutzt du Variablen im Code

```hcl
# String Interpolation
name = "${var.instance_name}-sg"

# Direkter Zugriff
region = var.aws_region

# Array-Zugriff
instance_count = var.instance_count

# Map-Zugriff
tags = var.instance_tags

# Object-Zugriff
instance_type = var.instance_config.instance_type
```

## Variablen setzen - 3 Wege

**1. Default im Code**
```hcl
variable "instance_name" {
  default = "my-server"
}
```

**2. terraform.tfvars Datei**
```hcl
instance_name       = "prod-server"
instance_count      = 3
enable_public_ip    = false
allowed_ssh_cidrs   = ["10.0.0.0/8"]
instance_tags       = { Environment = "prod", Team = "DevOps" }
instance_config     = { instance_type = "t3.small", volume_size = 50 }
```

**3. Command Line**
```bash
terraform apply -var="instance_name=prod-server" -var="instance_count=3"
```

## Validierung

```hcl
variable "instance_count" {
  type    = number
  default = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5
    error_message = "Muss zwischen 1 und 5 sein."
  }
}
```

## Warum terraform.tfvars und nicht default Werte in main.tf?

### Problem mit Defaults in main.tf:
```hcl
# ❌ NICHT EMPFOHLEN - Defaults in main.tf
variable "instance_name" {
  type    = string
  default = "my-webserver"  # Wert hardcodiert!
}
```

Probleme:
- ❌ Code-Änderung nötig um Werte zu ändern
- ❌ Unterschiedliche Umgebungen (dev, staging, prod) schwierig
- ❌ Team-Zusammenarbeit kompliziert
- ❌ Werte können in Git-History sichtbar sein

### Richtig mit terraform.tfvars:
```hcl
# ✅ EMPFOHLEN - Variable nur definieren
variable "instance_name" {
  type    = string
  default = "my-webserver"  # Fallback nur!
}

# Werte in separater Datei
# terraform.tfvars
instance_name = "prod-webserver"  # Aktuell, nicht im Code!
```

### Vorteile von terraform.tfvars:

| Vorteil | Erklärung |
|---------|-----------|
| **Trennung** | Code (main.tf) und Konfiguration (terraform.tfvars) getrennt |
| **Wiederverwendbar** | Ein main.tf für dev, staging, prod mit verschiedenen .tfvars |
| **Team-freundlich** | Verschiedene Umgebungen ohne Code zu ändern |
| **Git-sicher** | .gitignore: `*.tfvars` → Sensitive Daten nicht committen |
| **Einfach austauschbar** | `dev.tfvars`, `staging.tfvars`, `prod.tfvars` |
| **Flexibel** | Variablen auch per Command Line oder Environment überschreibbar |

## Praktisches Beispiel

```
project/
├── main.tf                  # Infrastruktur-Code (UNVERÄNDERLICH)
├── dev.tfvars         # Dev-Umgebung Werte (PRIVAT)
├── staging.tfvars          # Staging-Umgebung Werte
├── prod.tfvars             # Production-Umgebung Werte
└── .gitignore              # *.tfvars hier rein!
```

So nutzt man verschiedene Umgebungen:
```bash
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="staging.tfvars"
terraform plan -var-file="prod.tfvars"
```

## Wichtige Begriffe

| Begriff | Bedeutung |
|---------|-----------|
| `type` | Datentyp (string, number, bool, list, map, object) |
| `default` | Fallback-Wert wenn nicht angegeben |
| `description` | Dokumentation der Variable |
| `validation` | Überprüfung der Eingaben |
| `var.` | So greifst du auf Variablen zu |
| `terraform.tfvars` | Datei mit konkreten Werten (Terraform liest auto) |
| `-var-file` | Andere .tfvars Datei laden (z.B. prod.tfvars) |

