#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
# Installation XFCE + TigerVNC + noVNC pour Termux
# Accès au bureau XFCE depuis un navigateur web.
# ============================================================

set -o pipefail

# ---------- Couleurs et fonctions ----------
ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[0;33m'
BLEU='\033[0;34m'
NEUTRE='\033[0m'

afficher_etape()  { echo -e "${BLEU}[*]${NEUTRE} $1"; }
afficher_succes() { echo -e "${VERT}[✓]${NEUTRE} $1"; }
afficher_erreur() { echo -e "${ROUGE}[✗]${NEUTRE} $1"; }
afficher_avert()  { echo -e "${JAUNE}[!]${NEUTRE} $1"; }

# ---------- Vérification Termux ----------
if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
    afficher_erreur "Ce script doit être exécuté dans Termux."
    exit 1
fi

if [ ! -t 0 ]; then
    afficher_erreur "Ce script a besoin d'un terminal interactif. Téléchargez-le puis lancez-le avec bash."
    exit 1
fi

echo "=========================================="
echo "  Installation XFCE + noVNC pour Termux"
echo "=========================================="
echo ""

# ---------- Mise à jour et paquets ----------
afficher_etape "Mise à jour de Termux..."
if ! pkg update -y || ! pkg upgrade -y; then
    afficher_erreur "Échec de la mise à jour de Termux."
    exit 1
fi

afficher_etape "Ajout du dépôt X11..."
if ! pkg install x11-repo -y; then
    afficher_erreur "Échec de l'ajout du dépôt X11."
    exit 1
fi

afficher_etape "Installation de XFCE, TigerVNC, Python et Git..."
if ! pkg install xfce4 tigervnc python git -y; then
    afficher_erreur "Échec de l'installation des paquets."
    exit 1
fi

# websockify est fourni par le dépôt Termux lorsqu'il est disponible.
afficher_etape "Installation de websockify..."
if ! pkg install python-websockify -y; then
    afficher_avert "Le paquet Termux python-websockify n'est pas disponible. Tentative avec pip..."
    if ! pip install --user websockify; then
        afficher_erreur "Impossible d'installer websockify."
        exit 1
    fi
fi

# ---------- Installation/mise à jour noVNC ----------
NOVNC_DIR="$HOME/noVNC"
afficher_etape "Installation de noVNC dans $NOVNC_DIR..."
if [ -d "$NOVNC_DIR/.git" ]; then
    if ! git -C "$NOVNC_DIR" pull --ff-only; then
        afficher_erreur "Impossible de mettre à jour le dépôt noVNC existant."
        exit 1
    fi
elif [ -e "$NOVNC_DIR" ]; then
    afficher_erreur "$NOVNC_DIR existe déjà mais n'est pas un dépôt Git. Déplacez-le ou supprimez-le, puis relancez le script."
    exit 1
elif ! git clone --depth 1 https://github.com/novnc/noVNC.git "$NOVNC_DIR"; then
    afficher_erreur "Échec du téléchargement de noVNC."
    exit 1
fi

if [ ! -x "$NOVNC_DIR/utils/novnc_proxy" ]; then
    afficher_erreur "Le lanceur utils/novnc_proxy de noVNC est introuvable."
    exit 1
fi

# ---------- Configuration XFCE/VNC ----------
afficher_etape "Configuration de TigerVNC et XFCE..."
mkdir -p "$HOME/.vnc" || { afficher_erreur "Impossible de créer ~/.vnc."; exit 1; }

cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x "$HOME/.vnc/xstartup"

# ---------- Mot de passe VNC ----------
afficher_etape "Configuration du mot de passe VNC..."
echo -e "${JAUNE}Choisissez un mot de passe de 6 à 8 caractères.${NEUTRE}"
while true; do
    read -r -s -p "Mot de passe VNC : " vncpass
    echo
    read -r -s -p "Confirmez le mot de passe : " vncpass2
    echo

    if [ "$vncpass" != "$vncpass2" ]; then
        afficher_erreur "Les mots de passe ne correspondent pas."
        continue
    fi
    if [ "${#vncpass}" -lt 6 ] || [ "${#vncpass}" -gt 8 ]; then
        afficher_erreur "Le mot de passe doit contenir entre 6 et 8 caractères."
        continue
    fi
    break
done

if ! printf '%s\n' "$vncpass" | vncpasswd -f > "$HOME/.vnc/passwd"; then
    afficher_erreur "Impossible d'enregistrer le mot de passe VNC."
    exit 1
fi
chmod 600 "$HOME/.vnc/passwd"
unset vncpass vncpass2
afficher_succes "Mot de passe VNC configuré."

# ---------- Commandes de gestion noVNC ----------
afficher_etape "Création des commandes novnc-start/stop/status/log..."

cat > "$PREFIX/bin/novnc-start" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
NOVNC_DIR="$HOME/noVNC"
VNC_DISPLAY=':1'
VNC_PORT=5901
WEB_PORT="${NOVNC_PORT:-6080}"

if [ ! -x "$NOVNC_DIR/utils/novnc_proxy" ]; then
    echo "Erreur : noVNC est introuvable dans $NOVNC_DIR."
    exit 1
fi
if ! command -v websockify >/dev/null 2>&1; then
    echo "Erreur : websockify n'est pas installé ou absent du PATH."
    exit 1
fi

if ! vncserver -list 2>/dev/null | grep -q "$VNC_DISPLAY"; then
    if ! vncserver "$VNC_DISPLAY" -geometry "${VNC_GEOMETRY:-1280x720}" -depth 24 -localhost yes; then
        echo "Erreur : impossible de démarrer TigerVNC. Consultez ~/.vnc/*.log."
        exit 1
    fi
fi

if pgrep -f '[n]ovnc_proxy.*--listen' >/dev/null 2>&1 || pgrep -f '[w]ebsockify.*6080' >/dev/null 2>&1; then
    echo "noVNC semble déjà actif. Ouvrez http://127.0.0.1:${WEB_PORT}/vnc.html"
    exit 0
fi

nohup "$NOVNC_DIR/utils/novnc_proxy" --vnc "localhost:${VNC_PORT}" --listen "127.0.0.1:${WEB_PORT}" > "$HOME/.vnc/novnc.log" 2>&1 </dev/null &
sleep 2
if ! kill -0 "$!" 2>/dev/null; then
    echo "Erreur : noVNC n'a pas démarré. Consultez novnc-log."
    exit 1
fi

echo "noVNC est démarré. Ouvrez : http://127.0.0.1:${WEB_PORT}/vnc.html"
echo "Mot de passe : celui défini pendant l'installation."
EOF
chmod +x "$PREFIX/bin/novnc-start"

cat > "$PREFIX/bin/novnc-stop" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
NOVNC_PIDS="$(pgrep -f '[n]ovnc_proxy.*--listen' 2>/dev/null || true)"
if [ -n "$NOVNC_PIDS" ]; then
    kill $NOVNC_PIDS 2>/dev/null || true
fi
vncserver -kill :1 2>/dev/null || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
echo "noVNC et le serveur VNC sont arrêtés."
EOF
chmod +x "$PREFIX/bin/novnc-stop"

cat > "$PREFIX/bin/novnc-status" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
if vncserver -list 2>/dev/null | grep -q ':1'; then
    echo "TigerVNC actif sur le port 5901."
else
    echo "TigerVNC arrêté."
fi
if pgrep -f '[n]ovnc_proxy.*--listen' >/dev/null 2>&1 || pgrep -f '[w]ebsockify.*6080' >/dev/null 2>&1; then
    echo "noVNC actif : http://127.0.0.1:${NOVNC_PORT:-6080}/vnc.html"
else
    echo "noVNC arrêté."
fi
EOF
chmod +x "$PREFIX/bin/novnc-status"

cat > "$PREFIX/bin/novnc-log" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
if [ -f "$HOME/.vnc/novnc.log" ]; then
    tail -f "$HOME/.vnc/novnc.log"
else
    echo "Aucun log noVNC trouvé."
fi
EOF
chmod +x "$PREFIX/bin/novnc-log"

afficher_succes "Installation terminée. Commandes : novnc-start, novnc-stop, novnc-status, novnc-log."
echo ""
echo "Par défaut, noVNC écoute uniquement sur ce téléphone (127.0.0.1:6080)."
echo "Pour démarrer : novnc-start"
echo "Puis ouvrez : http://127.0.0.1:6080/vnc.html"
echo ""
echo "Pour arrêter : novnc-stop"
echo "Pour consulter les logs : novnc-log"
echo ""
afficher_avert "L'accès réseau depuis un autre appareil n'est pas activé par défaut. Ne l'activez que sur un réseau de confiance : le trafic HTTP/VNC n'est pas chiffré."
