# Übung 3: SQS Queue mit Dead Letter Queue
# Dauer: ~15 Minuten
#
# Aufgabe:
# Erstelle hier deine Lösung auf Basis der Dokumentation im README.md
#
# Hinweise:
# - Du brauchst ZWEI aws_sqs_queue Resources (main + dlq)
# - Die Main Queue braucht ein "redrive_policy" Attribut
# - Nutze jsonencode() um die Policy zu erstellen
# - Die Policy braucht: deadLetterTargetArn und maxReceiveCount
# - Referenziere die DLQ mit: aws_sqs_queue.dead_letter.arn
# - Füge Tags hinzu
# - Erstelle Outputs für beide Queue URLs und ARNs
#
# Wichtig: Erstelle ZUERST die DLQ, dann die Main Queue!
