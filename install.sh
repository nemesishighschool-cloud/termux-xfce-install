#!/data/data/com.termux/files/usr/bin/bash

# ============================================
# Script d'installation Bureau XFCE + VNC
# pour Termux (sans proot-distro)
# Version corrigée et structurée
# ============================================

set -o pipefail

# ---------- Couleurs ----------
ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[0;33m'
BLEU='\033[0;34m'
NEUTRE='\033[0m'

# ---------- Fonctions d'affichage ----------
afficher_etape()  { echo -e "${BLEU}[*]${NEUTRE} $1"; }
afficher_succes() { echo -e "${VERT}[✓]${NEUTRE} $1"; }
afficher_erreur() { echo -e "${ROUGE}[✗]${NEUTRE} $1"; }
afficher_avert()  { echo -e "${JAUNE}[!]${NEUTRE} $1"; }

# ---------- Vérification Termux ----------
if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ]; then
    afficher_erreur "Ce script doit être exécuté dans Termux."
    exit 1
fi

echo "=========================================="
echo "  Installation Bureau XFCE + VNC"
echo "=========================================="
echo ""

# ---------- 1. Mise à jour ----------
afficher_etape "Mise à jour de Termux..."
pkg update -y && pkg upgrade -y || { afficher_erreur "Erreur lors de la mise à jour"; exit 1; }
afficher_succes "Mise à jour terminée"

# ---------- 2. Dépôt X11 ----------
afficher_etape "Ajout du dépôt X11..."
pkg install x11-repo -y || { afficher_erreur "Erreur lors de l'ajout du dépôt X11"; exit 1; }
afficher_succes "Dépôt X11 ajouté"

# ---------- 3. Installation XFCE + TigerVNC ----------
afficher_etape "Installation de XFCE et TigerVNC (cela peut prendre du temps)..."
pkg install xfce4 tigervnc -y || { afficher_erreur "Erreur lors de l'installation"; exit 1; }
afficher_succes "XFCE et TigerVNC installés"

# ---------- 4. Dossier .vnc et xstartup ----------
afficher_etape "Création du dossier de configuration VNC..."
mkdir -p "$HOME/.vnc"

cat > "$HOME/.vnc/xstartup" << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x "$HOME/.vnc/xstartup"
afficher_succes "Fichier xstartup créé"

# ---------- 5. Mot de passe VNC ----------
afficher_etape "Configuration du mot de passe VNC..."
echo -e "${JAUNE}Le mot de passe doit contenir entre 6 et 8 caractères.${NEUTRE}"

while true; do
    read -r -s -p "Mot de passe VNC : " vncpass
    echo
    read -r -s -p "Confirmez le mot de passe : " vncpass2
    echo

    if [ "$vncpass" != "$vncpass2" ]; then
        afficher_erreur "Les mots de passe ne correspondent pas."
        continue
    fi

    if [ ${#vncpass} -lt 6 ] || [ ${#vncpass} -gt 8 ]; then
        afficher_erreur "Le mot de passe doit contenir entre 6 et 8 caractères."
        continue
    fi

    break
done

printf '%s\n' "$vncpass" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
afficher_succes "Mot de passe VNC configuré"

# ---------- 6. Création des commandes VNC ----------
afficher_etape "Création des commandes VNC..."

# vncstart
cat > "$PREFIX/bin/vncstart" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
vncserver :1 -geometry 1280x720 -depth 24 -localhost no
EOF
chmod +x "$PREFIX/bin/vncstart"

# vncstop
cat > "$PREFIX/bin/vncstop" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
vncserver -kill :1 2>/dev/null || true
EOF
chmod +x "$PREFIX/bin/vncstop"

# vncrestart
cat > "$PREFIX/bin/vncrestart" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
vncserver -kill :1 2>/dev/null || true
rm -rf /tmp/.X1* 2>/dev/null
vncserver :1 -geometry 1280x720 -depth 24 -localhost no
EOF
chmod +x "$PREFIX/bin/vncrestart"

# vncstatus
cat > "$PREFIX/bin/vncstatus" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ps aux | grep -E "Xvnc|vncserver" | grep -v grep
EOF
chmod +x "$PREFIX/bin/vncstatus"

# vnclog
cat > "$PREFIX/bin/vnclog" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
tail -f "$HOME/.vnc/"*.log 2>/dev/null || echo "Aucun log VNC trouvé."
EOF
chmod +x "$PREFIX/bin/vnclog"

afficher_succes "Commandes VNC créées : vncstart, vncstop, vncrestart, vncstatus, vnclog"

# ---------- 7. Nettoyage des anciens alias ----------
afficher_etape "Nettoyage des anciens alias dans .bashrc..."
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# ===== Alias VNC =====/,/# =====================/d' "$HOME/.bashrc" 2>/dev/null || true
fi
afficher_succes "Anciens alias supprimés"

# ---------- Résumé ----------
echo ""
echo "=========================================="
echo -e "${VERT}Installation terminée avec succès !${NEUTRE}"
echo "=========================================="
echo ""
echo "📋 Commandes disponibles :"
echo "   vncstart    : Démarrer VNC"
echo "   vncstop     : Arrêter VNC"
echo "   vncrestart  : Redémarrer VNC"
echo "   vncstatus   : Vérifier si VNC tourne"
echo "   vnclog      : Voir les logs"
echo ""
echo "📱 Connexion :"
echo "   Client VNC : AVNC (recommandé)"
echo "   Adresse    : 127.0.0.1:5901 (local) ou IP_DU_TELEPHONE:5901 (réseau)"
echo "   Mot de passe : celui que vous avez défini"
echo ""
echo "🚀 Pour démarrer VNC maintenant, tapez : vncstart"
echo ""

# ---------- Démarrage immédiat ----------
read -r -p "Voulez-vous démarrer VNC maintenant ? (o/N) " -n 1 reply
echo
if [[ $reply =~ ^[OoYy]$ ]]; then
    echo ""
    afficher_etape "Démarrage de VNC..."
    vncstart
    if [ $? -eq 0 ]; then
        afficher_succes "VNC démarré sur le port 5901"
        echo "📱 Connectez-vous avec AVNC à l'adresse : 127.0.0.1:5901"
    else
        afficher_erreur "Erreur au démarrage. Tapez 'vncstart' manuellement plus tard."
    fi
fi

echo ""
echo -e "${VERT}Bon bureau ! 🎉${NEUTRE}"