# SNS → SQS → SNS Integration - AWS Console Aufgabe

## Übersicht
In dieser Aufgabe baust du eine Message-Integration mit AWS SNS (Simple Notification Service) und SQS (Simple Queue Service) über die AWS Console auf. Dies ist ein klassisches Pattern für asynchrone Messaging-Systeme.

**Architektur:**
```
SNS Topic 1 (Quelle)
    ↓
SQS Queue (Message-Speicher)
    ↓
SNS Topic 2 (Ziel)
    ↓
Email-Benachrichtigung
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
| **Name** | `sns-sqs-sns-queue` | Eindeutiger Name für die Queue |
| **Typ** | Standard | Standard Queue für diese Aufgabe |
| **Message Retention Period** | 4 Minuten | Wie lange Messages in der Queue bleiben |
| **Visibility Timeout** | 30 Sekunden | Zeit, in der eine Message anderen Consumer nicht sichtbar ist |
| **Encryption** | Aus (für diese Demo) | Keine Verschlüsselung nötig |

### Schritt 3: Queue erstellen
- Klicke auf **Queue erstellen**
- Notiere dir die **Queue URL**: Diese brauchst du später
- Beispiel: `https://sqs.eu-central-1.amazonaws.com/123456789012/sns-sqs-sns-queue`

---

## Phase 2: SNS Topic 1 erstellen (Quelle)

### Schritt 1: SNS Console öffnen
1. Navigiere zu **Simple Notification Service (SNS)**
2. Klicke auf **Topic erstellen**

### Schritt 2: Topic-Konfiguration
| Eigenschaft | Wert |
|---|---|
| **Name** | `sns-sqs-sns-source-topic` |
| **Typ** | Standard |
| **Display Name** (Optional) | `SNS Source Topic` |

### Schritt 3: Topic erstellen
- Klicke auf **Topic erstellen**
- Notiere dir die **Topic ARN**: Diese brauchst du für Subscriptions
- Beispiel: `arn:aws:sns:eu-central-1:123456789012:sns-sqs-sns-source-topic`

---

## Phase 3: SNS Topic 1 → SQS Queue Subscription

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
      "Resource": "arn:aws:sqs:REGION:ACCOUNT:sns-sqs-sns-queue",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:REGION:ACCOUNT:sns-sqs-sns-source-topic"
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

## Phase 4: SNS Topic 2 erstellen (Ziel für Email)

### Schritt 1: Zweites Topic erstellen
1. Navigiere zu SNS
2. Klicke auf **Topic erstellen**

### Schritt 2: Topic-Konfiguration
| Eigenschaft | Wert |
|---|---|
| **Name** | `sns-sqs-sns-target-topic` |
| **Typ** | Standard |
| **Display Name** | `SNS Target Topic` |

### Schritt 3: Topic erstellen
- Notiere dir die **Topic ARN** des Target Topics

**⚠️ WICHTIG:**
- Dies ist ein **ANDERES Topic** als das Source Topic
- Das verhindert Recursion und teure Schleifen
- Du publishst in Topic 1, die Queue wird abgerufen, dann publishst du in Topic 2

---

## Phase 5: Email-Benachrichtigung für SNS Topic 2 einrichten

### Schritt 1: Subscription erstellen
1. Öffne dein **SNS Target Topic** (`sns-sqs-sns-target-topic`)
2. Klicke auf **Subscription erstellen**

### Schritt 2: Email-Subscription konfigurieren
| Eigenschaft | Wert |
|---|---|
| **Protokoll** | Email |
| **Endpoint** | deine@email.de |

### Schritt 3: Subscription bestätigen
1. Öffne dein Email-Postfach
2. Suche nach einer Bestätigungsmail von AWS SNS
3. Klicke auf **Confirm subscription**
4. Das Target Topic zeigt jetzt Status: **Bestätigt**

### Schritt 4: SQS Message Handlers (optional, für tieferes Verständnis)
In einer echten Applikation würde eine Komponente:
1. Messages aus der SQS Queue abrufen
2. Message verarbeiten
3. Message in SNS Topic 2 publishen

Für diese Demo tun wir das manuell.

---

## Phase 6: Test - Messages publishen und empfangen

### Test 1: Message in Source Topic publishen

1. Öffne **SNS Source Topic** (`sns-sqs-sns-source-topic`)
2. Klicke auf **Publish message**
3. Konfiguriere:
   | Feld | Wert |
   |---|---|
   | **Subject** | `Test Message` |
   | **Message body** | `Dies ist meine erste Message in der SNS→SQS→SNS Pipeline!` |

4. Klicke auf **Publish message**

### Test 2: Message in SQS Queue überprüfen

1. Navigiere zur **SQS Queue** (`sns-sqs-sns-queue`)
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
  "TopicArn": "arn:aws:sns:...:sns-sqs-sns-source-topic",
  "Subject": "Test Message",
  "Message": "Dies ist meine erste Message in der SNS→SQS→SNS Pipeline!",
  "Timestamp": "2024-10-22T10:30:00.000Z",
  "SignatureVersion": "1",
  "SigningCertUrl": "...",
  "Signature": "...",
  "UnsubscribeUrl": "..."
}
```

5. Klicke auf die Message → **Delete** (um sie aus der Queue zu entfernen)

### Test 3: Message in Target Topic publishen (simuliert Queue-Verarbeitung)

Jetzt simulieren wir, dass ein Consumer die Message aus der Queue verarbeitet hat und sie ins Target Topic publisht.

1. Öffne **SNS Target Topic** (`sns-sqs-sns-target-topic`)
2. Klicke auf **Publish message**
3. Konfiguriere:
   | Feld | Wert |
   |---|---|
   | **Subject** | `Processed Message` |
   | **Message body** | `Dies ist die verarbeitete Message!` |

4. Klicke auf **Publish message**

### Test 4: Email empfangen

1. Überprüfe dein Email-Postfach
2. Du solltest eine Email von SNS mit dem Betreff `Processed Message` erhalten

---

## Checkliste - Hast du alles?

- [ ] SQS Queue erstellt und Queue URL notiert
- [ ] SNS Source Topic erstellt und ARN notiert
- [ ] SNS → SQS Subscription erstellt
- [ ] SQS Queue Policy aktualisiert (SNS darf Messages senden)
- [ ] SNS Target Topic erstellt und ARN notiert
- [ ] SNS Target Topic → Email Subscription erstellt und bestätigt
- [ ] Test 1: Message in Source Topic published
- [ ] Test 2: Message in SQS Queue gefunden
- [ ] Test 3: Message in Target Topic published
- [ ] Test 4: Email empfangen

---

## Wichtige Konzepte zusammengefasst

| Konzept | Bedeutung |
|---|---|
| **SNS Topic** | Publikations-Punkt für Messages (Pub/Sub Pattern) |
| **SQS Queue** | Nachrichten-Speicher mit Polling (Async Processing) |
| **Subscription** | Verbindung zwischen Topic und Ziel (Queue, Email, Lambda, etc.) |
| **Message Format** | SNS packt die Message in JSON (ohne Raw Message Delivery) |
| **Permissions** | SNS braucht Policy auf der SQS Queue, um Messages zu senden |
| **Recursion Prevention** | Nie das gleiche Topic 2x verwenden (zu teuer!) |

---