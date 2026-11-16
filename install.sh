#!/data/data/com.termux/files/usr/bin/bash

# ============================================
# Script d'installation Bureau XFCE + VNC
# pour Termux (sans proot-distro)
# ============================================

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

# ---------- Vérification Termux ----------
if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX:-}" ]; then
    afficher_erreur "Ce script doit être exécuté dans Termux."
    exit 1
fi

# ---------- Mise à jour et installation ----------
echo "=========================================="
echo "  Installation Bureau XFCE + VNC"
echo "=========================================="
echo ""

afficher_etape "Mise à jour de Termux..."
if ! pkg update -y || ! pkg upgrade -y; then
    afficher_erreur "Erreur lors de la mise à jour. Vérifiez votre connexion et les dépôts Termux."
    exit 1
fi
afficher_succes "Mise à jour terminée"

afficher_etape "Ajout du dépôt X11..."
if ! pkg install x11-repo -y; then
    afficher_erreur "Erreur lors de l'ajout du dépôt X11."
    exit 1
fi
afficher_succes "Dépôt X11 ajouté"

afficher_etape "Installation de XFCE et TigerVNC (cela peut prendre du temps)..."
if ! pkg install xfce4 tigervnc -y; then
    afficher_erreur "Erreur lors de l'installation de XFCE/TigerVNC. Vérifiez les dépôts Termux et relancez le script."
    exit 1
fi

# Vérifier le binaire après installation, jamais avant.
if ! command -v vncserver >/dev/null 2>&1; then
    afficher_erreur "TigerVNC a été demandé mais la commande vncserver reste introuvable. Essayez 'pkg install tigervnc' puis relancez le script."
    exit 1
fi
afficher_succes "XFCE et TigerVNC installés"

# ---------- Dossier .vnc et xstartup ----------
afficher_etape "Création du dossier de configuration VNC..."
mkdir -p "$HOME/.vnc" || { afficher_erreur "Impossible de créer ~/.vnc."; exit 1; }

cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
if command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session startxfce4
else
    exec startxfce4
fi
EOF
chmod +x "$HOME/.vnc/xstartup"
afficher_succes "Fichier xstartup créé"

# ---------- Mot de passe VNC ----------
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
afficher_succes "Mot de passe VNC configuré"

# ---------- Création des commandes VNC ----------
afficher_etape "Création des commandes VNC..."

cat > "$PREFIX/bin/vncstart" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
if ! command -v vncserver >/dev/null 2>&1; then
    echo "Erreur : vncserver est introuvable. Installez TigerVNC avec : pkg install tigervnc"
    exit 1
fi
if vncserver -list 2>/dev/null | grep -q ':1'; then
    echo "Le serveur VNC est déjà actif sur :1."
    exit 0
fi
exec vncserver :1 -geometry 1280x720 -depth 24 -localhost no
EOF
chmod +x "$PREFIX/bin/vncstart"

cat > "$PREFIX/bin/vncstop" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
vncserver -kill :1 2>/dev/null || true
EOF
chmod +x "$PREFIX/bin/vncstop"

cat > "$PREFIX/bin/vncrestart" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
vncserver -kill :1 2>/dev/null || true
sleep 1
exec vncserver :1 -geometry 1280x720 -depth 24 -localhost no
EOF
chmod +x "$PREFIX/bin/vncrestart"

cat > "$PREFIX/bin/vncstatus" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
if vncserver -list 2>/dev/null | grep -q ':1'; then
    vncserver -list
else
    echo "Aucun serveur VNC actif sur :1."
fi
EOF
chmod +x "$PREFIX/bin/vncstatus"

cat > "$PREFIX/bin/vnclog" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
shopt -s nullglob
logs=("$HOME"/.vnc/*.log)
if ((${#logs[@]})); then
    tail -f "${logs[@]}"
else
    echo "Aucun log VNC trouvé dans ~/.vnc/."
fi
EOF
chmod +x "$PREFIX/bin/vnclog"

afficher_succes "Commandes créées : vncstart, vncstop, vncrestart, vncstatus, vnclog"

# ---------- Nettoyage des anciens alias ----------
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# ===== Alias VNC =====/,/# =====================/d' "$HOME/.bashrc" 2>/dev/null || true
fi

# ---------- Résumé ----------
echo ""
echo "=========================================="
echo -e "${VERT}Installation terminée avec succès !${NEUTRE}"
echo "=========================================="
echo ""
echo "Commandes disponibles : vncstart, vncstop, vncrestart, vncstatus, vnclog"
echo "Connexion VNC : 127.0.0.1:5901 (local) ou IP_DU_TELEPHONE:5901 (réseau)"
echo "Mot de passe : celui défini pendant l'installation"
echo ""

if [ -t 0 ]; then
    read -r -p "Voulez-vous démarrer VNC maintenant ? (o/N) " -n 1 reply
    echo
    if [[ "$reply" =~ ^[OoYy]$ ]]; then
        afficher_etape "Démarrage de VNC..."
        if vncstart; then
            afficher_succes "VNC démarré sur le port 5901"
        else
            afficher_erreur "Échec du démarrage. Consultez les logs avec vnclog."
        fi
    fi
fi

echo ""
echo -e "${VERT}Bon bureau ! 🎉${NEUTRE}"
