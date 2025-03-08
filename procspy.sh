#!/bin/bash

# Capture du signal SIGINT pour quitter proprement avec Ctrl+C
trap "echo -e '\n[+] Script arrêté.'; exit 0" SIGINT

echo "🔍 Surveillance des processus de 'backup'. Appuie sur 'q' pour quitter."

while true; do
    # Vérifier si l'utilisateur appuie sur 'q' pour quitter
    read -t 1 -n 1 key
    if [[ "$key" == "q" ]]; then
        echo -e "\n[+] Sortie demandée par l'utilisateur."
        exit 0
    fi

    # Récupérer l'UID de l'utilisateur cible
    TARGET_UID=$(id -u backup 2>/dev/null)

    if [ -z "$TARGET_UID" ]; then
        echo "[-] Utilisateur 'backup' introuvable."
        exit 1
    fi

    # Parcourir tous les processus
    for pid in $(ls /proc | grep -E '^[0-9]+$'); do
        # Vérifier si le processus existe toujours
        if [ -d "/proc/$pid" ]; then
            PROC_UID=$(stat -c %u /proc/$pid 2>/dev/null)

            # Si le processus appartient à l'utilisateur cible
            if [ "$PROC_UID" -eq "$TARGET_UID" ] 2>/dev/null; then
                echo "🔍 Processus détecté : PID $pid exécuté par c2-api"

                # Lire la commande exécutée
                echo "📜 Commande exécutée :"
                tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || echo "[-] Impossible de lire cmdline"
                echo -e "\n"

                # Lire les variables d’environnement
                echo "🌍 Variables d’environnement :"
                tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null || echo "[-] Impossible de lire environ"
                echo -e "\n----------------------\n"
            fi
        fi
    done
done
