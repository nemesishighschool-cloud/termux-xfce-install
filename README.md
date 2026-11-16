# termux-xfce-install

> Installation d'un bureau XFCE dans Termux avec TigerVNC, avec au choix un client VNC classique ou une interface noVNC accessible dans un navigateur.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Description

Ce projet installe un environnement de bureau graphique **XFCE** dans **Termux** (Android), sans root ni `proot-distro`. Deux scripts sont proposés :

- `install.sh` : XFCE et TigerVNC, pour se connecter avec une application cliente VNC.
- `install-novnc.sh` : XFCE, TigerVNC et noVNC, pour utiliser le bureau depuis le navigateur web du téléphone.

Les deux scripts configurent le mot de passe VNC et les commandes de démarrage et d'arrêt correspondantes.

## Prérequis

- **Termux** installé depuis [F-Droid](https://f-droid.org/packages/com.termux/) ou une source officielle maintenue. Évitez les versions obsolètes du Play Store.
- Android 7.0 ou version ultérieure.
- Une connexion Internet.

## Installation

Ouvre Termux et choisis **une** des méthodes ci-dessous.

### XFCE avec une application VNC (TigerVNC)

Télécharge puis exécute le script :

```bash
curl -fsSL https://raw.githubusercontent.com/nemesishighschool-cloud/termux-xfce-install/main/install.sh -o install.sh && bash install.sh
```

### XFCE accessible depuis un navigateur (noVNC)

Télécharge puis exécute le second script :

```bash
curl -fsSL https://raw.githubusercontent.com/nemesishighschool-cloud/termux-xfce-install/main/install-novnc.sh -o install-novnc.sh && bash install-novnc.sh
```

Le téléchargement dans un fichier avant l'exécution permet au script d'utiliser le terminal pour demander le mot de passe VNC.

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

Après l'installation noVNC :

```bash
novnc-start
```

Ouvre ensuite cette adresse dans le navigateur du téléphone :

```text
http://127.0.0.1:6080/vnc.html
```

Saisis le mot de passe VNC défini pendant l'installation. Les commandes disponibles sont :

| Commande | Fonction |
|----------|----------|
| `novnc-start` | Démarre TigerVNC et l'interface noVNC |
| `novnc-stop` | Arrête TigerVNC et noVNC |
| `novnc-status` | Affiche l'état des services |
| `novnc-log` | Affiche les logs noVNC en temps réel |

Par sécurité, noVNC écoute par défaut uniquement sur `127.0.0.1` : le bureau est accessible dans le navigateur du téléphone, mais pas depuis d'autres appareils du réseau. L'accès distant nécessite de modifier l'adresse d'écoute et doit être réservé à un réseau de confiance; le trafic HTTP/VNC n'est pas chiffré.

## Utilisation avec un client VNC classique

Avec `install.sh`, démarre le serveur et connecte un client VNC au port 5901 :

```bash
vncstart
```

Adresse locale : `127.0.0.1:5901`. Commandes de gestion : `vncstart`, `vncstop`, `vncrestart`, `vncstatus` et `vnclog`.

## Dépannage

- Si une commande n'est pas trouvée, ferme puis rouvre Termux, ou recharge ton shell avec `source ~/.bashrc`.
- Les logs VNC sont dans `~/.vnc/`; utilise `vnclog` ou `novnc-log` selon le script installé.
- Le mot de passe VNC doit contenir entre 6 et 8 caractères. Pour le changer, lance `vncpasswd`, puis redémarre le serveur.
- Si le port est déjà utilisé, arrête les services avec `vncstop` ou `novnc-stop`, puis relance-les.

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
