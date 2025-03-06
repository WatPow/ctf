#!/bin/bash

# Script de reconnaissance pour l'escalade de privilèges
# Créé pour un CTF

echo "======================================"
echo "SCRIPT DE RECONNAISSANCE POUR PRIVESC"
echo "======================================"
echo ""

# Création du dossier pour les résultats
RESULTS_DIR="privesc_recon_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Fonction pour enregistrer les résultats
save_output() {
    echo -e "\n[+] $1"
    eval "$2" | tee -a "$RESULTS_DIR/$3"
    echo -e "\n----- Résultats enregistrés dans $RESULTS_DIR/$3 -----\n"
}

# Informations système de base
save_output "Informations système" "uname -a" "1_system_info.txt"
save_output "Version de la distribution" "cat /etc/*-release 2>/dev/null || cat /etc/issue 2>/dev/null" "1_system_info.txt"
save_output "Informations sur le processeur" "lscpu 2>/dev/null || cat /proc/cpuinfo 2>/dev/null" "1_system_info.txt"
save_output "Informations sur la mémoire" "free -h" "1_system_info.txt"
save_output "Uptime du système" "uptime" "1_system_info.txt"

# Informations sur l'utilisateur
save_output "Utilisateur actuel" "id" "2_user_info.txt"
save_output "Utilisateurs du système" "cat /etc/passwd" "2_user_info.txt"
save_output "Dernières connexions" "last | head -n 20" "2_user_info.txt"
save_output "Utilisateurs connectés" "w" "2_user_info.txt"
save_output "Historique des commandes" "cat ~/.bash_history 2>/dev/null" "2_user_info.txt"
save_output "Variables d'environnement" "env" "2_user_info.txt"

# Informations sur les privilèges
save_output "Fichiers SUID" "find / -type f -perm -4000 -ls 2>/dev/null" "3_privileges.txt"
save_output "Fichiers SGID" "find / -type f -perm -2000 -ls 2>/dev/null" "3_privileges.txt"
save_output "Fichiers avec capacités" "getcap -r / 2>/dev/null" "3_privileges.txt"
save_output "Droits sudo" "sudo -l 2>/dev/null" "3_privileges.txt"
save_output "Fichiers world-writable" "find / -type f -perm -o+w -ls 2>/dev/null" "3_privileges.txt"
save_output "Dossiers world-writable" "find / -type d -perm -o+w -ls 2>/dev/null" "3_privileges.txt"

# Processus et services
save_output "Processus en cours" "ps aux" "4_processes.txt"
save_output "Services en cours" "systemctl list-units --type=service 2>/dev/null || service --status-all 2>/dev/null || ls -la /etc/init.d/ 2>/dev/null" "4_processes.txt"
save_output "Processus avec timer" "systemctl list-timers --all 2>/dev/null" "4_processes.txt"
save_output "Tâches cron" "ls -la /etc/cron* 2>/dev/null && cat /etc/crontab 2>/dev/null && cat /var/spool/cron/crontabs/* 2>/dev/null" "4_processes.txt"

# Réseau
save_output "Interfaces réseau" "ip a || ifconfig" "5_network.txt"
save_output "Routes réseau" "ip route || route" "5_network.txt"
save_output "Connexions réseau" "netstat -tuln || ss -tuln" "5_network.txt"
save_output "Règles iptables" "iptables -L 2>/dev/null" "5_network.txt"
save_output "Fichier hosts" "cat /etc/hosts" "5_network.txt"
save_output "Fichier resolv.conf" "cat /etc/resolv.conf" "5_network.txt"

# Logiciels et versions
save_output "Logiciels installés (dpkg)" "dpkg -l 2>/dev/null" "6_software.txt"
save_output "Logiciels installés (rpm)" "rpm -qa 2>/dev/null" "6_software.txt"
save_output "Versions des logiciels courants" "python --version 2>/dev/null; python3 --version 2>/dev/null; ruby --version 2>/dev/null; perl --version 2>/dev/null; gcc --version 2>/dev/null; bash --version 2>/dev/null" "6_software.txt"

# Montages et disques
save_output "Montages" "mount" "7_filesystems.txt"
save_output "Partitions" "df -h" "7_filesystems.txt"
save_output "Fichier fstab" "cat /etc/fstab" "7_filesystems.txt"

# Fichiers intéressants
save_output "Fichiers de configuration sensibles" "find /etc -type f -name '*.conf' -o -name '*.config' -o -name 'config' -ls 2>/dev/null | head -n 50" "8_interesting_files.txt"
save_output "Fichiers de mot de passe" "find / -name '*.pwd' -o -name '*.password' -o -name '*.pass' -o -name 'credentials' -ls 2>/dev/null" "8_interesting_files.txt"
save_output "Fichiers de clés" "find / -name '*.key' -o -name '*.pem' -o -name 'id_rsa*' -ls 2>/dev/null" "8_interesting_files.txt"
save_output "Fichiers de configuration web" "find / -name 'wp-config.php' -o -name '.htpasswd' -o -name 'config.php' -o -name 'settings.php' -ls 2>/dev/null" "8_interesting_files.txt"
save_output "Fichiers récemment modifiés" "find / -type f -mtime -7 -not -path '/proc/*' -not -path '/sys/*' -not -path '/run/*' -not -path '/dev/*' -not -path '/var/log/*' -ls 2>/dev/null | head -n 50" "8_interesting_files.txt"

# Docker
save_output "Informations Docker" "docker info 2>/dev/null; docker ps -a 2>/dev/null; docker images 2>/dev/null" "9_containers.txt"
save_output "Informations LXC" "lxc list 2>/dev/null" "9_containers.txt"

# Vulnérabilités connues
save_output "Vérification de vulnérabilités kernel" "grep -i 'model name' /proc/cpuinfo 2>/dev/null; grep -i 'flags' /proc/cpuinfo 2>/dev/null | grep -i 'spectre\|meltdown\|retpoline\|kaiser'" "10_vulnerabilities.txt"
save_output "Vérification de DirtyCow" "grep -i 'dirty cow' /proc/cpuinfo 2>/dev/null || grep -i 'dirty_cow' /proc/cpuinfo 2>/dev/null" "10_vulnerabilities.txt"

# Résumé
echo "======================================"
echo "RECONNAISSANCE TERMINÉE"
echo "======================================"
echo "Résultats enregistrés dans le dossier: $RESULTS_DIR"
echo "Vérifiez les fichiers pour identifier des vecteurs d'escalade de privilèges potentiels."
echo "======================================"
