
# termux-xfce-install

> Installation automatique d'un bureau XFCE et d'un serveur VNC (TigerVNC) dans Termux, sans proot-distro.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📖 Description

Ce projet permet d'installer rapidement un environnement de bureau graphique **XFCE** dans **Termux** (Android), accessible via **VNC**. Il ne nécessite ni root, ni proot-distro, ni aucune autre surcouche.

Le script `install.sh` gère automatiquement :
- La mise à jour de Termux
- L'ajout du dépôt X11
- L'installation de XFCE et TigerVNC
- La création du fichier `~/.vnc/xstartup`
- La configuration sécurisée du mot de passe VNC (6 à 8 caractères)
- La création de commandes pratiques : `vncstart`, `vncstop`, `vncrestart`, `vncstatus`, `vnclog`
- Le nettoyage des anciens alias dans `~/.bashrc`

## ⚙️ Prérequis

- **Termux** installé depuis [F-Droid](https://f-droid.org/packages/com.termux/) (la version du Play Store est obsolète).
- **Android 7.0** ou version ultérieure.
- Une connexion Internet active.
- Un client VNC sur le même appareil ou sur un autre appareil du réseau (nous recommandons **AVNC** sur Android, ou **TigerVNC** / **RealVNC** sur PC).

## 🚀 Installation

### Méthode rapide (curl)

Ouvre Termux et exécute la commande suivante :

```bash
curl -sL https://raw.githubusercontent.com/nemesishighschool-cloud/termux-xfce-install/main/install.sh | bash
```

> **Note** : Si tu préfères vérifier le script avant de l'exécuter, télécharge-le d'abord :
> ```bash
> curl -sL https://raw.githubusercontent.com/nemesishighschool-cloud/termux-xfce-install/main/install.sh -o install.sh
> less install.sh   # pour lire le contenu
> bash install.sh
> ```

### Méthode par clonage Git

```bash
pkg install git -y
git clone https://github.com/nemesishighschool-cloud/termux-xfce-install.git
cd termux-xfce-install
bash install.sh
```

## 🖥️ Utilisation

Une fois l'installation terminée, tu disposes des commandes suivantes :

| Commande | Description |
|----------|-------------|
| `vncstart` | Démarre le serveur VNC sur le port 5901 |
| `vncstop` | Arrête le serveur VNC |
| `vncrestart` | Redémarre le serveur VNC |
| `vncstatus` | Affiche les processus VNC en cours |
| `vnclog` | Affiche les logs VNC en temps réel |

### Connexion au bureau

1. Lance le serveur VNC :
   ```bash
   vncstart
   ```

2. Ouvre ton client VNC et connecte-toi à :
   - **Adresse** : `127.0.0.1:5901` (si le client est sur le même appareil)
   - **Adresse** : `IP_DE_TON_TELEPHONE:5901` (si le client est sur un autre appareil du réseau)
   - **Mot de passe** : celui que tu as défini lors de l'installation

3. Tu devrais voir apparaître le bureau XFCE.

### Arrêt du serveur

```bash
vncstop
```

## 🔧 Dépannage

### Les commandes `vncstart` etc. ne sont pas trouvées

Assure-toi que `$PREFIX/bin` est dans ton `PATH` (c'est normalement le cas par défaut dans Termux). Si besoin, recharge ton shell :

```bash
source ~/.bashrc
```

Ou ferme et rouvre Termux.

### Le mot de passe VNC est refusé

Le mot de passe doit contenir **entre 6 et 8 caractères**. Si tu l'as oublié, tu peux le redéfinir :

```bash
vncpasswd
```

Puis relance `vncstart`.

### Le serveur VNC ne démarre pas

Vérifie les logs :

```bash
vnclog
```

Ou consulte le fichier `~/.vnc/*.log`.

### Erreur « Address already in use »

Un serveur VNC tourne peut-être déjà. Arrête-le :

```bash
vncstop
```

Puis relance `vncstart`.

### L'écran est noir ou XFCE ne se lance pas

Vérifie que le fichier `~/.vnc/xstartup` contient bien :

```sh
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
```

Si ce n'est pas le cas, corrige-le et redémarre VNC.

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus d'informations.

## 🙏 Remerciements

- [Termux](https://termux.com/)
- [XFCE](https://xfce.org/)
- [TigerVNC](https://tigervnc.org/)
- [AVNC](https://github.com/gujjwal00/avnc) (client VNC Android recommandé)

---

**Bon bureau ! 🎉**
