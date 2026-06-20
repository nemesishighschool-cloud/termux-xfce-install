#!/data/data/com.termux/files/usr/bin/bash

# ============================================
# Script d'installation Bureau XFCE + VNC
# pour Termux (sans proot-distro)
# ============================================

echo "=========================================="
echo "  Installation Bureau XFCE + VNC"
echo "=========================================="
echo ""

# Couleurs pour l'affichage
ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[0;33m'
BLEU='\033[0;34m'
NEUTRE='\033[0m'

# Fonction d'affichage
afficher_etape() {
    echo -e "${BLEU}[*]${NEUTRE} $1"
}

afficher_succes() {
    echo -e "${VERT}[✓]${NEUTRE} $1"
}

afficher_erreur() {
    echo -e "${ROUGE}[✗]${NEUTRE} $1"
}

# Vérifier que Termux est à jour
afficher_etape "Mise à jour de Termux..."
pkg update -y && pkg upgrade -y
if [ $? -eq 0 ]; then
    afficher_succes "Mise à jour terminée"
else
    afficher_erreur "Erreur lors de la mise à jour"
    exit 1
fi

# Ajouter le dépôt X11
afficher_etape "Ajout du dépôt X11..."
pkg install x11-repo -y
if [ $? -eq 0 ]; then
    afficher_succes "Dépôt X11 ajouté"
else
    afficher_erreur "Erreur lors de l'ajout du dépôt X11"
    exit 1
fi

# Installer XFCE et TigerVNC
afficher_etape "Installation de XFCE et TigerVNC (cela peut prendre du temps)..."
pkg install xfce4 tigervnc -y
if [ $? -eq 0 ]; then
    afficher_succes "XFCE et TigerVNC installés"
else
    afficher_erreur "Erreur lors de l'installation"
    exit 1
fi

# Créer le dossier .vnc
afficher_etape "Création du dossier de configuration VNC..."
mkdir -p ~/.vnc
afficher_succes "Dossier ~/.vnc créé"

# Créer le fichier xstartup
afficher_etape "Création du fichier xstartup..."
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4 &
EOF
chmod +x ~/.vnc/xstartup
afficher_succes "Fichier xstartup créé et exécutable"

# Configurer le mot de passe VNC
afficher_etape "Configuration du mot de passe VNC..."
echo ""
echo -e "${JAUNE}!!! Veuillez entrer un mot de passe pour VNC !!!${NEUTRE}"
echo -e "${JAUNE}!!! 8 caractères maximum, tapez-le deux fois !!!${NEUTRE}"
echo ""
vncpasswd
if [ $? -eq 0 ]; then
    afficher_succes "Mot de passe configuré"
else
    afficher_erreur "Erreur lors de la configuration du mot de passe"
    exit 1
fi

# Créer les alias dans .bashrc
afficher_etape "Ajout des alias dans .bashrc..."

# Supprimer les anciens alias s'ils existent
sed -i '/alias vnc/d' ~/.bashrc 2>/dev/null

# Ajouter les nouveaux alias
cat >> ~/.bashrc << 'EOF'

# ===== Alias VNC =====
alias vncstart='vncserver :1 -geometry 1024x600 -depth 16 -localhost no'
alias vncstop='vncserver -kill :1'
alias vnclog='tail -f ~/.vnc/localhost:1.log'
alias vncrestart='vncstop 2>/dev/null; rm -rf /tmp/.X1* 2>/dev/null; vncstart'
alias vncstatus='ps aux | grep -E "Xvnc|vncserver" | grep -v grep'
# =====================
EOF

# Recharger .bashrc dans le shell actuel
source ~/.bashrc

# Marquer le fichier .bashrc comme source automatique
echo "export BASH_ENV=~/.bashrc" >> ~/.bashrc 2>/dev/null

afficher_succes "Alias ajoutés et .bashrc rechargé"

echo ""
echo "=========================================="
echo -e "${VERT}Installation terminée avec succès !${NEUTRE}"
echo "=========================================="
echo ""

echo "📋 Commandes disponibles :"
echo "   ${VERT}vncstart${NEUTRE}    : Démarrer VNC"
echo "   ${VERT}vncstop${NEUTRE}     : Arrêter VNC"
echo "   ${VERT}vncrestart${NEUTRE}  : Redémarrer VNC"
echo "   ${VERT}vncstatus${NEUTRE}   : Vérifier si VNC tourne"
echo "   ${VERT}vnclog${NEUTRE}      : Voir les logs"
echo ""

echo "📱 Connexion :"
echo "   Client VNC : AVNC (recommandé)"
echo "   Adresse    : 127.0.0.1:5901 (local) ou IP_DU_TELEPHONE:5901 (réseau)"
echo "   Mot de passe: celui que vous avez défini"
echo ""

echo -e "${JAUNE}⚠️  Note : Pour les connexions depuis un PC, l'option -localhost no est déjà activée${NEUTRE}"
echo ""
echo "🚀 Pour démarrer VNC maintenant, tapez : vncstart"
echo ""

# Proposer de démarrer VNC immédiatement
read -p "Voulez-vous démarrer VNC maintenant ? (o/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    echo ""
    afficher_etape "Démarrage de VNC..."
    source ~/.bashrc
    vncstart
    if [ $? -eq 0 ]; then
        afficher_succes "VNC démarré sur le port 5901"
        echo ""
        echo "📱 Connectez-vous maintenant avec AVNC à l'adresse : 127.0.0.1:5901"
    else
        afficher_erreur "Erreur au démarrage. Tapez 'vncstart' manuellement plus tard"
    fi
fi

echo ""
echo -e "${VERT}Bon bureau ! 🎉${NEUTRE}"
echo ""
echo -e "${JAUNE}💡 Astuce : Si les alias ne sont pas disponibles dans un nouveau terminal,${NEUTRE}"
echo -e "${JAUNE}   tapez 'source ~/.bashrc' ou fermez et rouvrez Termux.${NEUTRE}"
