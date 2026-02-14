# VanadielXI Auto-Updater System

## 📋 Vue d'ensemble

Système complet de mise à jour automatique pour VanadielXI qui vérifie et installe les mises à jour toutes les 10 minutes.

**Architecture :**
- **Serveur** : nginx + PHP sur LXC Debian (https://vanadielxi-updates.duckdns.org)
- **Client** : Programme Windows C# qui tourne en arrière-plan

---

## 🖥️ Partie Serveur (Déjà configuré ✅)

Votre serveur nginx est déjà opérationnel avec :

### Fichiers serveur
```
/var/www/html/updates/
├── update_server.php        # API de mise à jour
├── version.txt              # Version actuelle (ex: 1.0.0)
├── update_manifest.txt      # Liste des fichiers à mettre à jour
├── update_manifest.sh       # Script pour regénérer le manifeste
└── files/                   # Fichiers de mise à jour
    └── ROM/
        ├── 24/
        │   ├── 127.DAT
        │   └── 37.DAT
        └── 25/
            ├── 39.DAT
            └── 40.DAT
```

### API Endpoints disponibles
- `?action=check_version` - Obtenir la version actuelle
- `?action=get_manifest` - Liste des fichiers à mettre à jour
- `?action=download&file=ROM/24/127.DAT` - Télécharger un fichier
- `?action=info` - Informations complètes

### Comment publier une mise à jour

1. **Ajouter vos fichiers .DAT mis à jour** :
```bash
# Copier vos nouveaux fichiers dans le dossier approprié
cp nouveau_fichier.DAT /var/www/html/updates/files/ROM/24/

# Vérifier les permissions
chmod 644 /var/www/html/updates/files/ROM/24/nouveau_fichier.DAT
chown www-data:www-data /var/www/html/updates/files/ROM/24/nouveau_fichier.DAT
```

2. **Regénérer le manifeste** :
```bash
cd /var/www/html/updates/
./update_manifest.sh
```

3. **Mettre à jour le numéro de version** :
```bash
echo "1.0.1" > /var/www/html/updates/version.txt
```

4. **Tester** :
```bash
curl "http://localhost/updates/update_server.php?action=check_version"
curl "http://localhost/updates/update_server.php?action=get_manifest"
```

---

## 💻 Partie Client (À compiler)

### Prérequis pour la compilation

**Sur Windows :**
1. Installer .NET SDK 6.0 ou supérieur
   - Télécharger depuis : https://dotnet.microsoft.com/download
2. Installer NSIS (Nullsoft Scriptable Install System)
   - Télécharger depuis : https://nsis.sourceforge.io/Download

### Compilation du Client Auto-Updater

```powershell
# 1. Aller dans le dossier du projet
cd vanadielxi-updater

# 2. Compiler l'updater
dotnet publish VanadielXI_Updater.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

# 3. L'exécutable sera dans :
# bin\Release\net6.0-windows\win-x64\publish\VanadielXI_Updater.exe
```

### Compilation de l'installeur NSIS

```powershell
# 1. Copier VanadielXI_Updater.exe dans le dossier de compilation NSIS
copy bin\Release\net6.0-windows\win-x64\publish\VanadielXI_Updater.exe .

# 2. Compiler avec NSIS
"C:\Program Files (x86)\NSIS\makensis.exe" FINAL_FANTASY_XI_v2_1_with_updater.nsi

# 3. L'installeur sera créé : FINAL FANTASY XI.exe
```

---

## 🚀 Installation côté utilisateur

### Ce que fait l'installeur :

1. Installe le jeu FINAL FANTASY XI
2. Configure Windower4
3. **Installe VanadielXI_Updater.exe**
4. **Crée version.txt** avec la version initiale
5. **Ajoute l'updater au démarrage automatique**
6. **Lance l'updater**

### Comportement de l'Auto-Updater

**Au démarrage :**
- L'updater se lance automatiquement avec Windows
- Une icône apparaît dans la barre des tâches (system tray)
- Vérification immédiate des mises à jour

**Toutes les 10 minutes :**
- Vérification silencieuse en arrière-plan
- Si mise à jour disponible → notification + popup de confirmation
- Si l'utilisateur accepte → téléchargement et installation automatiques

**Menu contextuel (clic droit sur l'icône) :**
- "Vérifier les mises à jour" - Force une vérification manuelle
- "Quitter" - Ferme l'updater

---

## 🔧 Configuration

### Modifier l'intervalle de vérification

Éditer `VanadielXI_Updater.cs` ligne 21 :
```csharp
private static readonly int CHECK_INTERVAL_MINUTES = 10; // Changer ici
```

### Modifier l'URL du serveur

Éditer `VanadielXI_Updater.cs` ligne 18 :
```csharp
private static readonly string UPDATE_SERVER = "https://vanadielxi-updates.duckdns.org/update_server.php";
```

---

## 📝 Logs et débogage

### Logs client (Windows)
```
C:\Users\<USERNAME>\AppData\Local\Temp\VanadielXI_Updater.log
```

### Logs serveur (Linux)
```bash
# Logs nginx
tail -f /var/log/nginx/updates_access.log
tail -f /var/log/nginx/updates_error.log

# Logs PHP
tail -f /var/www/html/updates/updates.log
```

---

## 🔒 Sécurité

✅ Communication HTTPS (SSL note A)
✅ Validation des chemins de fichiers (anti path traversal)
✅ Vérification de version avant téléchargement
✅ Logs d'accès avec IP

---

## 📊 Structure du système de versioning

**Serveur :**
- `version.txt` contient : `1.0.0`
- `update_manifest.txt` liste les fichiers

**Client :**
- `C:\Program Files\PlayOnline\version.txt` stocke la version installée
- Comparaison serveur vs local à chaque vérification

**Processus de mise à jour :**
```
Client vérifie (toutes les 10 min)
    ↓
Serveur répond avec version
    ↓
Client compare versions
    ↓
Si différent → Popup confirmation
    ↓
Téléchargement fichiers du manifeste
    ↓
Installation dans ROM/24/ et ROM/25/
    ↓
Mise à jour version.txt local
```

---

## 🎯 Exemples d'utilisation

### Publier une mise à jour 1.0.1 avec nouveaux fichiers

```bash
# 1. Copier les nouveaux fichiers
scp nouveau_127.DAT root@nginx:/var/www/html/updates/files/ROM/24/

# 2. Se connecter au serveur
ssh root@nginx

# 3. Ajuster permissions
cd /var/www/html/updates
chmod 644 files/ROM/24/nouveau_127.DAT
chown www-data:www-data files/ROM/24/nouveau_127.DAT

# 4. Regénérer le manifeste
./update_manifest.sh

# 5. Mettre à jour la version
echo "1.0.1" > version.txt

# 6. Vérifier
curl "http://localhost/updates/update_server.php?action=check_version"
```

**Résultat :** Dans les 10 minutes, tous les clients seront notifiés de la nouvelle version !

---

## ❓ FAQ

**Q: Comment désactiver les mises à jour automatiques ?**
R: Clic droit sur l'icône → Quitter. Pour désactiver définitivement, supprimer la clé de registre :
```
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\VanadielXI_Updater
```

**Q: L'updater ne démarre pas au lancement de Windows ?**
R: Vérifier la clé de registre ci-dessus existe et pointe vers le bon chemin.

**Q: Comment forcer une mise à jour ?**
R: Clic droit sur l'icône → "Vérifier les mises à jour"

**Q: Les fichiers ne se téléchargent pas ?**
R: Vérifier les permissions sur le serveur et les logs dans `VanadielXI_Updater.log`

---

## 📞 Support

Pour tout problème :
1. Vérifier les logs (client et serveur)
2. Tester l'API manuellement : `curl https://vanadielxi-updates.duckdns.org/update_server.php?action=check_version`
3. Vérifier que nginx et PHP-FPM tournent : `systemctl status nginx php8.4-fpm`

---

## ✨ Fonctionnalités futures possibles

- [ ] Barre de progression pour les téléchargements
- [ ] Vérification de hash MD5/SHA256 pour l'intégrité
- [ ] Téléchargement en arrière-plan sans bloquer
- [ ] Support de patchs différentiels (delta updates)
- [ ] Rollback automatique en cas d'échec
- [ ] Interface graphique complète pour gérer l'updater

---

**Créé par Fox_Mulder pour VanadielXI Server**
**License: ZLIB - Copyright (c) 2023-2026**
