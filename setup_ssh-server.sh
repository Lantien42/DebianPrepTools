#!/bin/bash

# Variables
USER=$1
PORT=$2

# Fonction pour afficher l'aide
usage() {
    echo "Usage: $0 -user <username> -port <port>"
    exit 1
}

# Vérification des arguments
if [ $# -ne 4 ]; then
    usage
fi

# Analyse des arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -user) USER="$2"; shift ;;
        -port) PORT="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Mise à jour des paquets
apt-get update

# Installation de sudo
apt-get install -y sudo

# Ajout de l'utilisateur au groupe sudo
usermod -aG sudo $USER

# Installation de OpenSSH Server
apt-get install -y openssh-server

# Configuration de SSH
sed -i "s/#Port 22/Port $PORT/" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config

# Redémarrage du service SSH
systemctl restart ssh

# Installation de fail2ban
apt-get install -y fail2ban

# Configuration de fail2ban
cat <<EOL > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = $PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOL

# Redémarrage de fail2ban
systemctl restart fail2ban

# Ajout de la clé publique SSH pour l'utilisateur
mkdir -p /home/$USER/.ssh
cat <<EOF > /home/$USER/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKw0JhxyuwUdWZa3ebL6dAxQepcGDLaOIU6Cvo27c9+8 mickael@equenot.test
EOF
chown -R $USER:$USER /home/$USER/.ssh
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys

echo "Script ssh-server terminé avec succès."
