# SNS → SQS Integration - AWS Console Aufgabe

## Übersicht
In dieser Aufgabe baust du eine Message-Integration mit AWS SNS (Simple Notification Service) und SQS (Simple Queue Service) über die AWS Console auf. Dies ist ein klassisches Pattern für asynchrone Messaging-Systeme.

**Architektur:**
```
SNS Topic (Quelle)
    ↓
SQS Queue (Message-Speicher)
```

---

## Phase 1: SQS Queue erstellen

### Schritt 1: SQS Console öffnen
1. Melde dich in der [AWS Console](https://console.aws.amazon.com) an
2. Navigiere zu **Simple Queue Service (SQS)**
3. Klicke auf **Queue erstellen**

### Schritt 2: Queue-Konfiguration
Verwende folgende Einstellungen:

| Eigenschaft | Wert | Erklärung |
|---|---|---|
| **Name** | `sns-sqs-queue` | Eindeutiger Name für die Queue |
| **Typ** | Standard | Standard Queue für diese Aufgabe |
| **Message Retention Period** | 4 Minuten | Wie lange Messages in der Queue bleiben |
| **Visibility Timeout** | 30 Sekunden | Zeit, in der eine Message anderen Consumer nicht sichtbar ist |
| **Encryption** | Aus (für diese Demo) | Keine Verschlüsselung nötig |

### Schritt 3: Queue erstellen
- Klicke auf **Queue erstellen**
- Notiere dir die **Queue URL**: Diese brauchst du später
- Beispiel: `https://sqs.eu-central-1.amazonaws.com/123456789012/sns-sqs-queue`

---

## Phase 2: SNS Topic erstellen

### Schritt 1: SNS Console öffnen
1. Navigiere zu **Simple Notification Service (SNS)**
2. Klicke auf **Topic erstellen**

### Schritt 2: Topic-Konfiguration
| Eigenschaft | Wert |
|---|---|
| **Name** | `sns-sqs-topic` |
| **Typ** | Standard |
| **Display Name** (Optional) | `SNS Source Topic` |

### Schritt 3: Topic erstellen
- Klicke auf **Topic erstellen**
- Notiere dir die **Topic ARN**: Diese brauchst du für Subscriptions
- Beispiel: `arn:aws:sns:eu-central-1:123456789012:sns-sqs-topic`

---

## Phase 3: SNS Topic → SQS Queue Subscription

### Schritt 1: Subscription hinzufügen
1. Im SNS Topic öffnen
2. Scrolle zu **Subscriptions** und klicke auf **Subscription erstellen**

### Schritt 2: Subscription-Konfiguration
| Eigenschaft | Wert |
|---|---|
| **Protokoll** | SQS |
| **Endpoint** | Deine SQS Queue ARN |
| **Raw Message Delivery** | Aus (wichtig für Message Format) |

### Schritt 3: Queue-Permissions aktualisieren
**Wichtig:** SNS braucht die Permission, Messages an diese SQS Queue zu senden.

1. Gehe zur SQS Queue
2. Klicke auf **Access Policy**
3. Klicke auf **Edit** und ersetze den Inhalt mit:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:REGION:ACCOUNT:sns-sqs-queue",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:REGION:ACCOUNT:sns-sqs-topic"
        }
      }
    }
  ]
}
```

**Ersetze:**
- `REGION` → z.B. `eu-north-1`
- `ACCOUNT` → deine AWS Account ID
- ARNs entsprechend anpassen

4. Klicke auf **Save**

---

## Phase 4: Test - Messages publishen und empfangen

### Test 1: Message in SNS Topic publishen

1. Öffne **SNS Topic** (`sns-sqs-topic`)
2. Klicke auf **Publish message**
3. Konfiguriere:
   | Feld | Wert |
   |---|---|
   | **Subject** | `Test Message` |
   | **Message body** | `Dies ist meine erste Message in der SNS→SQS Pipeline!` |

4. Klicke auf **Publish message**

### Test 2: Message in SQS Queue überprüfen

1. Navigiere zur **SQS Queue** (`sns-sqs-queue`)
2. Klicke auf **Send and receive messages**
3. Klicke auf **Poll for messages**
4. Du solltest eine Message sehen mit:
   - **Message Attributes** (enthält SNS Metadaten)
   - **Body** (die eigentliche Nachricht im SNS Format)

**Beachte:** Die Message ist im SNS JSON-Format verpackt, da wir "Raw Message Delivery" ausgeschaltet haben.

Beispiel Body:
```json
{
  "Type": "Notification",
  "MessageId": "12345-abcde",
  "TopicArn": "arn:aws:sns:...:sns-sqs-topic",
  "Subject": "Test Message",
  "Message": "Dies ist meine erste Message in der SNS→SQS Pipeline!",
  "Timestamp": "2024-10-22T10:30:00.000Z",
  "SignatureVersion": "1",
  "SigningCertUrl": "...",
  "Signature": "...",
  "UnsubscribeUrl": "..."
}
```

5. Klicke auf die Message → **Delete** (um sie aus der Queue zu entfernen)

---

## Checkliste - Hast du alles?

- [ ] SQS Queue erstellt und Queue URL notiert
- [ ] SNS Topic erstellt und ARN notiert
- [ ] SNS → SQS Subscription erstellt
- [ ] SQS Queue Policy aktualisiert (SNS darf Messages senden)
- [ ] Test 1: Message in SNS Topic published
- [ ] Test 2: Message in SQS Queue gefunden

---

## Wichtige Konzepte zusammengefasst

| Konzept | Bedeutung |
|---|---|
| **SNS Topic** | Publikations-Punkt für Messages (Pub/Sub Pattern) |
| **SQS Queue** | Nachrichten-Speicher mit Polling (Async Processing) |
| **Subscription** | Verbindung zwischen Topic und Queue |
| **Message Format** | SNS packt die Message in JSON (ohne Raw Message Delivery) |
| **Permissions** | SNS braucht Policy auf der SQS Queue, um Messages zu senden |

---
