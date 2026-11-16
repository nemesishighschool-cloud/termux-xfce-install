# termux-xfce-install

> Installation d'un bureau XFCE dans Termux avec TigerVNC, au choix avec un client VNC classique ou via noVNC dans un navigateur.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Description

Ce projet installe un environnement de bureau graphique **XFCE** dans **Termux** (Android), sans root ni `proot-distro`. Deux scripts sont disponibles :

- `install.sh` : XFCE et TigerVNC, pour un client VNC classique.
- `install-novnc.sh` : XFCE, TigerVNC et noVNC, pour accéder au bureau via un navigateur sur le téléphone ou sur un appareil du même réseau local.

## Prérequis

- **Termux** installé depuis [F-Droid](https://f-droid.org/packages/com.termux/) ou une source officielle maintenue. Évitez les versions obsolètes du Play Store.
- Android 7.0 ou version ultérieure.
- Une connexion Internet.

## Installation

Ouvre Termux et choisis **une** des méthodes ci-dessous.

### XFCE avec un client VNC classique

```bash
curl -fsSL https://raw.githubusercontent.com/nemesishighschool-cloud/termux-xfce-install/main/install.sh -o install.sh && bash install.sh
```

### XFCE accessible depuis un navigateur (noVNC)

```bash
curl -fsSL https://raw.githubusercontent.com/nemesishighschool-cloud/termux-xfce-install/main/install-novnc.sh -o install-novnc.sh && bash install-novnc.sh
```

Le téléchargement dans un fichier avant l'exécution permet au script de demander le mot de passe VNC dans le terminal.

### Installation par clonage Git

```bash
pkg install git -y
git clone https://github.com/nemesishighschool-cloud/termux-xfce-install.git
cd termux-xfce-install
bash install.sh
# Ou, pour l'accès navigateur :
bash install-novnc.sh
```

## Utilisation de noVNC

Démarre noVNC avec l'une de ces commandes :

```bash
start-novnc
# Alias équivalent :
novnc-start
```

Ouvre ensuite l'interface dans le navigateur :

- Sur le téléphone : `http://127.0.0.1:6080/vnc.html`
- Depuis un autre appareil connecté au même réseau local/Wi-Fi : `http://IP_DU_TELEPHONE:6080/vnc.html`

Le script affiche l'adresse IP locale si Termux peut la détecter automatiquement. Sinon, affiche-la avec `ip -o -4 addr show scope global`. Saisis le mot de passe VNC défini pendant l'installation.

| Commande | Fonction |
|----------|----------|
| `start-novnc` / `novnc-start` | Démarre TigerVNC et noVNC |
| `stop-novnc` / `novnc-stop` | Arrête TigerVNC et noVNC |
| `status-novnc` / `novnc-status` | Affiche l'état des services |
| `log-novnc` / `novnc-log` | Affiche les logs noVNC en temps réel |

Les commandes courtes sont installées dans `$PREFIX/bin`; les alias Bash correspondants sont également ajoutés à `~/.bashrc`. Pour les charger dans le shell en cours :

```bash
source ~/.bashrc
```

### Sécurité réseau

noVNC écoute sur le réseau local afin que les autres appareils du même réseau puissent s'y connecter. Le serveur VNC lui-même reste lié à localhost et le mot de passe VNC est requis. Toutefois, l'interface web utilise HTTP non chiffré : utilise uniquement un réseau de confiance et **ne redirige pas le port 6080 vers Internet**. Les appareils doivent être sur le même réseau et le pare-feu/routeur ne doit pas bloquer le port.

## Utilisation avec un client VNC classique

Avec `install.sh`, démarre le serveur et connecte une application VNC au port 5901 :

```bash
vncstart
```

Adresse locale : `127.0.0.1:5901`. Commandes de gestion : `vncstart`, `vncstop`, `vncrestart`, `vncstatus` et `vnclog`.

## Dépannage

- Si une commande n'est pas trouvée, ferme puis rouvre Termux, ou recharge ton shell avec `source ~/.bashrc`.
- Les logs VNC sont dans `~/.vnc/`; utilise `vnclog` ou `log-novnc` selon le script installé.
- Le mot de passe VNC doit contenir entre 6 et 8 caractères. Pour le changer, lance `vncpasswd`, puis redémarre le serveur.
- Si le port est déjà utilisé, arrête les services avec `stop-novnc` ou `vncstop`, puis relance-les.

## Licence

Ce projet est distribué sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus d'informations.

## Remerciements

- [Termux](https://termux.com/)
- [XFCE](https://xfce.org/)
- [TigerVNC](https://tigervnc.org/)
- [noVNC](https://github.com/novnc/noVNC)
- [AVNC](https://github.com/gujjwal00/avnc), client VNC Android

---

**Bon bureau ! 🎉**
