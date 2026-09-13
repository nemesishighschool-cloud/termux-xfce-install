#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
# Script d'installation Bureau XFCE + noVNC (via websockify)
# pour Termux - Version complète et robuste
# ============================================================

set -o pipefail
set -u

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

# ---------- Vérification de l'environnement Termux ----------
if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX:-}" ]; then
    afficher_erreur "Ce script doit être exécuté dans Termux."
    exit 1
fi

# ---------- Vérification de la connectivité Internet ----------
afficher_etape "Vérification de la connexion Internet..."
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    afficher_avert "Aucune connexion Internet détectée. Certaines étapes pourraient échouer."
    read -r -p "Continuer quand même ? (o/N) " reply
    if [[ ! "$reply" =~ ^[OoYy]$ ]]; then
        afficher_erreur "Abandon."
        exit 1
    fi
else
    afficher_succes "Connexion Internet active."
fi

echo ""
echo "=========================================="
echo "  Installation Bureau XFCE + noVNC"
echo "=========================================="
echo ""

# ---------- 1. Mise à jour de Termux ----------
afficher_etape "Mise à jour de Termux..."
if ! pkg update -y && pkg upgrade -y; then
    afficher_erreur "Échec de la mise à jour de Termux."
    exit 1
fi
afficher_succes "Mise à jour terminée."

# ---------- 2. Ajout du dépôt X11 ----------
afficher_etape "Ajout du dépôt X11..."
if ! pkg install x11-repo -y; then
    afficher_erreur "Échec de l'ajout du dépôt X11."
    exit 1
fi
afficher_succes "Dépôt X11 ajouté."

# ---------- 3. Installation des paquets nécessaires ----------
afficher_etape "Installation de XFCE, TigerVNC, Python et Git (cela peut prendre du temps)..."
if ! pkg install xfce4 tigervnc python git -y; then
    afficher_erreur "Échec de l'installation des paquets."
    exit 1
fi
afficher_succes "Paquets installés."

# ---------- 4. Installation de websockify via pip ----------
afficher_etape "Installation de websockify via pip..."
if ! pip install websockify; then
    afficher_avert "Échec de l'installation via pip. Tentative via pkg..."
    if ! pkg install python-websockify -y; then
        afficher_erreur "Impossible d'installer websockify."
        exit 1
    fi
fi
afficher_succes "websockify installé."

# ---------- 5. Clonage de noVNC ----------
afficher_etape "Clonage du dépôt noVNC..."
NOVNC_DIR="$HOME/noVNC"
if [ -d "$NOVNC_DIR" ]; then
    afficher_avert "Le dossier $NOVNC_DIR existe déjà. Suppression..."
    rm -rf "$NOVNC_DIR"
fi
if ! git clone https://github.com/novnc/noVNC.git "$NOVNC_DIR"; then
    afficher_erreur "Échec du clonage de noVNC."
    exit 1
fi
afficher_succes "noVNC cloné dans $NOVNC_DIR."

# ---------- 6. Configuration du dossier .vnc et xstartup ----------
afficher_etape "Configuration de VNC..."
mkdir -p "$HOME/.vnc"

cat > "$HOME/.vnc/xstartup" << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x "$HOME/.vnc/xstartup"
afficher_succes "Fichier xstartup créé."

# ---------- 7. Mot de passe VNC (validation) ----------
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
afficher_succes "Mot de passe VNC configuré."

# ---------- 8. Création des commandes de gestion ----------
afficher_etape "Création des commandes de gestion..."

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
pkill -f websockify 2>/dev/null || true
EOF
chmod +x "$PREFIX/bin/vncstop"

# vncstatus
cat > "$PREFIX/bin/vncstatus" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ps aux | grep -E "Xvnc|vncserver|websockify" | grep -v grep
EOF
chmod +x "$PREFIX/bin/vncstatus"

# vnclog
cat > "$PREFIX/bin/vnclog" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
tail -f "$HOME/.vnc/"*.log 2>/dev/null || echo "Aucun log VNC trouvé."
EOF
chmod +x "$PREFIX/bin/vnclog"

afficher_succes "Commandes créées : vncstart, vncstop, vncstatus, vnclog."

# ---------- 9. Création des commandes noVNC ----------
afficher_etape "Création des commandes noVNC..."

# novnc-start
cat > "$PREFIX/bin/novnc-start" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
NOVNC_DIR="$HOME/noVNC"
if [ ! -d "$NOVNC_DIR" ]; then
    echo "Erreur : le dossier noVNC est introuvable."
    exit 1
fi
vncserver :1 -geometry 1280x720 -depth 24 -localhost no
sleep 2
cd "$NOVNC_DIR" || exit 1
nohup ./utils/novnc_proxy --vnc localhost:5901 --listen 6080 > "$HOME/.vnc/novnc.log" 2>&1 &
echo "noVNC démarré. Accès : http://127.0.0.1:6080/vnc.html"
EOF
chmod +x "$PREFIX/bin/novnc-start"

# novnc-stop
cat > "$PREFIX/bin/novnc-stop" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -f websockify 2>/dev/null || true
vncserver -kill :1 2>/dev/null || true
rm -rf /tmp/.X1* 2>/dev/null || true
echo "noVNC arrêté."
EOF
chmod +x "$PREFIX/bin/novnc-stop"

# novnc-status
cat > "$PREFIX/bin/novnc-status" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ps aux | grep -E "Xvnc|vncserver|websockify" | grep -v grep
EOF
chmod +x "$PREFIX/bin/novnc-status"

# novnc-log
cat > "$PREFIX/bin/novnc-log" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
tail -f "$HOME/.vnc/novnc.log" 2>/dev/null || echo "Aucun log noVNC trouvé."
EOF
chmod +x "$PREFIX/bin/novnc-log"

afficher_succes "Commandes noVNC créées : novnc-start, novnc-stop, novnc-status, novnc-log."

# ---------- Résumé ----------
echo ""
echo "=========================================="
echo -e "${VERT}Installation terminée avec succès !${NEUTRE}"
echo "=========================================="
echo ""
echo "📋 Commandes disponibles :"
echo "   vncstart       : Démarrer VNC (client classique)"
echo "   vncstop        : Arrêter VNC"
echo "   vncstatus      : Vérifier si VNC tourne"
echo "   vnclog         : Voir les logs VNC"
echo ""
echo "   novnc-start    : Démarrer VNC + noVNC (accès navigateur)"
echo "   novnc-stop     : Arrêter VNC + noVNC"
echo "   novnc-status   : Vérifier si noVNC tourne"
echo "   novnc-log      : Voir les logs noVNC"
echo ""
echo "🌐 Accès navigateur :"
echo "   http://127.0.0.1:6080/vnc.html"
echo "   (ou http://IP_DE_TON_TELEPHONE:6080/vnc.html depuis un autre appareil)"
echo ""
echo "🚀 Pour démarrer noVNC maintenant, tapez : novnc-start"
echo ""

# ---------- Démarrage immédiat (optionnel) ----------
read -r -p "Voulez-vous démarrer noVNC maintenant ? (o/N) " -n 1 reply
echo
if [[ "$reply" =~ ^[OoYy]$ ]]; then
    echo ""
    afficher_etape "Démarrage de noVNC..."
    novnc-start
    if [ $? -eq 0 ]; then
        afficher_succes "noVNC démarré sur le port 6080."
        echo "🌐 Ouvrez : http://127.0.0.1:6080/vnc.html"
    else
        afficher_erreur "Erreur au démarrage. Tapez 'novnc-start' manuellement plus tard."
    fi
fi

echo ""
echo -e "${VERT}Bon bureau ! 🎉${NEUTRE}"