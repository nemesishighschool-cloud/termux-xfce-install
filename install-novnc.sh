#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
# Installation XFCE + TigerVNC + noVNC pour Termux
# Accès au bureau XFCE via navigateur, sur le téléphone ou LAN.
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
afficher_etape "Création des commandes noVNC..."

cat > "$PREFIX/bin/novnc-start" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
NOVNC_DIR="$HOME/noVNC"
VNC_DISPLAY=':1'
VNC_PORT=5901
WEB_PORT="${NOVNC_PORT:-6080}"
PID_FILE="$HOME/.vnc/novnc.pid"
export PATH="$HOME/.local/bin:$PATH"

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

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "noVNC semble déjà actif sur le port ${WEB_PORT}."
    echo "Ouvrez http://127.0.0.1:${WEB_PORT}/vnc.html ou utilisez l'adresse IP du téléphone."
    exit 0
fi
rm -f "$PID_FILE"

# Le VNC lui-même reste limité à localhost; seul le proxy web écoute sur le LAN.
nohup "$NOVNC_DIR/utils/novnc_proxy" --vnc "localhost:${VNC_PORT}" --listen "0.0.0.0:${WEB_PORT}" > "$HOME/.vnc/novnc.log" 2>&1 </dev/null &
NOVNC_PID=$!
echo "$NOVNC_PID" > "$PID_FILE"
sleep 2
if ! kill -0 "$NOVNC_PID" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "Erreur : noVNC n'a pas démarré. Consultez novnc-log."
    exit 1
fi

LAN_IP=""
if command -v ip >/dev/null 2>&1; then
    LAN_IP="$(ip -o -4 addr show scope global 2>/dev/null | awk '{split($4,a,"/"); if (a[1] !~ /^127\./) {print a[1]; exit}}')"
fi

echo "noVNC est démarré sur le port ${WEB_PORT}."
echo "Sur ce téléphone : http://127.0.0.1:${WEB_PORT}/vnc.html"
if [ -n "$LAN_IP" ]; then
    echo "Sur le réseau local : http://${LAN_IP}:${WEB_PORT}/vnc.html"
else
    echo "Sur un autre appareil du même Wi-Fi : http://IP_DU_TELEPHONE:${WEB_PORT}/vnc.html"
    echo "Pour trouver l'adresse IP, utilisez : ip -o -4 addr show scope global"
fi
echo "Mot de passe : celui défini pendant l'installation."
EOF
chmod +x "$PREFIX/bin/novnc-start"

cat > "$PREFIX/bin/novnc-stop" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PID_FILE="$HOME/.vnc/novnc.pid"
if [ -f "$PID_FILE" ]; then
    NOVNC_PID="$(cat "$PID_FILE")"
    if [[ "$NOVNC_PID" =~ ^[0-9]+$ ]] && kill -0 "$NOVNC_PID" 2>/dev/null; then
        kill "$NOVNC_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi
vncserver -kill :1 2>/dev/null || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
echo "noVNC et le serveur VNC sont arrêtés."
EOF
chmod +x "$PREFIX/bin/novnc-stop"

cat > "$PREFIX/bin/novnc-status" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
WEB_PORT="${NOVNC_PORT:-6080}"
if vncserver -list 2>/dev/null | grep -q ':1'; then
    echo "TigerVNC actif sur le port 5901 (écoute locale uniquement)."
else
    echo "TigerVNC arrêté."
fi
if [ -f "$HOME/.vnc/novnc.pid" ] && kill -0 "$(cat "$HOME/.vnc/novnc.pid")" 2>/dev/null; then
    echo "noVNC actif : http://127.0.0.1:${WEB_PORT}/vnc.html"
    echo "Sur le réseau local : http://IP_DU_TELEPHONE:${WEB_PORT}/vnc.html"
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

# Noms courts demandés : commandes exécutables et alias Bash idempotents.
ln -sf novnc-start "$PREFIX/bin/start-novnc"
ln -sf novnc-stop "$PREFIX/bin/stop-novnc"
ln -sf novnc-status "$PREFIX/bin/status-novnc"
ln -sf novnc-log "$PREFIX/bin/log-novnc"

BASHRC="$HOME/.bashrc"
ALIAS_BEGIN="# >>> termux-xfce-install noVNC aliases >>>"
ALIAS_END="# <<< termux-xfce-install noVNC aliases <<<"
if [ -f "$BASHRC" ]; then
    sed -i "/$ALIAS_BEGIN/,/$ALIAS_END/d" "$BASHRC"
fi
cat >> "$BASHRC" <<'EOF'
# >>> termux-xfce-install noVNC aliases >>>
alias start-novnc='novnc-start'
alias stop-novnc='novnc-stop'
alias status-novnc='novnc-status'
alias log-novnc='novnc-log'
# <<< termux-xfce-install noVNC aliases <<<
EOF

afficher_succes "Installation terminée. Commandes : start-novnc/novnc-start, stop-novnc/novnc-stop, status-novnc/novnc-status, log-novnc/novnc-log."
echo ""
echo "Démarrer : start-novnc"
echo "Ouvrir sur le téléphone : http://127.0.0.1:6080/vnc.html"
echo "Depuis un appareil du même réseau Wi-Fi : http://IP_DU_TELEPHONE:6080/vnc.html"
echo "Arrêter : stop-novnc"
echo ""
afficher_avert "Sécurité : l'interface écoute sur le réseau local et utilise HTTP non chiffré. Utilisez uniquement un réseau Wi-Fi de confiance, gardez le mot de passe VNC, et ne redirigez pas le port 6080 vers Internet."
echo "Rechargez les alias Bash avec : source ~/.bashrc"
