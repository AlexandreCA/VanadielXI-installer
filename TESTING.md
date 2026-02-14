# 🧪 Guide de Test - VanadielXI Auto-Updater

## Test rapide du serveur (depuis le LXC nginx)

### 1. Vérifier que tout fonctionne
```bash
# Version actuelle
curl "http://localhost/updates/update_server.php?action=check_version"
# Devrait retourner : {"success":true,"version":"1.0.0","timestamp":...}

# Liste des fichiers
curl "http://localhost/updates/update_server.php?action=get_manifest"
# Devrait retourner : {"success":true,"files":["ROM/24/127.DAT","ROM/24/37.DAT",...]}

# Informations complètes
curl "http://localhost/updates/update_server.php?action=info"
```

### 2. Tester un téléchargement
```bash
# Télécharger un fichier spécifique
curl "http://localhost/updates/update_server.php?action=download&file=ROM/24/127.DAT" -o /tmp/test.DAT

# Vérifier la taille
ls -lh /tmp/test.DAT
```

### 3. Simuler une mise à jour

```bash
# Sauvegarder la version actuelle
cp /var/www/html/updates/version.txt /tmp/version_backup.txt

# Changer la version pour tester
echo "1.0.1" > /var/www/html/updates/version.txt

# Vérifier
curl "http://localhost/updates/update_server.php?action=check_version"
# Devrait retourner : {"success":true,"version":"1.0.1","timestamp":...}

# Restaurer la version originale
cp /tmp/version_backup.txt /var/www/html/updates/version.txt
```

---

## Test depuis l'extérieur (depuis votre PC)

### 1. Tester avec curl
```bash
curl "https://vanadielxi-updates.duckdns.org/update_server.php?action=check_version"
curl "https://vanadielxi-updates.duckdns.org/update_server.php?action=get_manifest"
```

### 2. Tester avec un navigateur
Ouvrez ces URLs dans votre navigateur :
```
https://vanadielxi-updates.duckdns.org/update_server.php?action=check_version
https://vanadielxi-updates.duckdns.org/update_server.php?action=get_manifest
https://vanadielxi-updates.duckdns.org/update_server.php?action=info
```

### 3. Tester un téléchargement
```
https://vanadielxi-updates.duckdns.org/update_server.php?action=download&file=ROM/24/127.DAT
```
→ Le fichier devrait se télécharger

---

## Test du client Windows (après compilation)

### Test 1 : Lancement manuel
```cmd
# Lancer l'updater
VanadielXI_Updater.exe

# Vérifier qu'une icône apparaît dans la barre des tâches
# Clic droit → "Vérifier les mises à jour"
```

### Test 2 : Vérifier les logs
```cmd
# Ouvrir le fichier de log
notepad %TEMP%\VanadielXI_Updater.log

# Devrait contenir :
# [2026-02-13 21:30:00] VanadielXI Updater démarré
# [2026-02-13 21:30:01] Vérification des mises à jour...
# [2026-02-13 21:30:02] Version actuelle : 1.0.0
# [2026-02-13 21:30:03] Version serveur : 1.0.0
# [2026-02-13 21:30:04] Le jeu est à jour
```

### Test 3 : Simuler une mise à jour

**Sur le serveur :**
```bash
# Changer la version
echo "1.0.1" > /var/www/html/updates/version.txt
```

**Sur le client Windows :**
- Attendre 10 minutes OU clic droit → "Vérifier les mises à jour"
- Une popup devrait apparaître : "Une nouvelle mise à jour est disponible !"
- Cliquer "Oui" pour installer
- Les fichiers du manifeste seront téléchargés

---

## Vérification de l'installation complète

### Après installation via NSIS :

**1. Vérifier les fichiers**
```cmd
dir "C:\Program Files\PlayOnline"
```
Devrait contenir :
- VanadielXI_Updater.exe ✅
- version.txt ✅
- SquareEnix\FINAL FANTASY XI\ROM\... ✅

**2. Vérifier le démarrage automatique**
```cmd
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v VanadielXI_Updater
```
Devrait retourner le chemin vers l'updater

**3. Vérifier que l'updater tourne**
```cmd
tasklist | findstr VanadielXI_Updater
```
Devrait afficher : VanadielXI_Updater.exe

---

## Scénarios de test complets

### Scénario 1 : Première installation
1. Lancer l'installeur NSIS
2. Suivre les étapes d'installation
3. À la fin, VanadielXI_Updater.exe se lance automatiquement
4. Notification : "Le service de mise à jour est actif"
5. Vérification immédiate → "Le jeu est à jour"

### Scénario 2 : Mise à jour disponible
1. Sur le serveur : `echo "1.0.1" > version.txt`
2. Attendre 10 minutes (ou forcer manuellement)
3. Popup : "Une nouvelle mise à jour est disponible !"
4. Accepter → Téléchargement des fichiers
5. Notification : "Mise à jour réussie"
6. Vérifier : `type "C:\Program Files\PlayOnline\version.txt"` → 1.0.1

### Scénario 3 : Redémarrage Windows
1. Redémarrer l'ordinateur
2. L'updater devrait se lancer automatiquement au démarrage
3. Icône visible dans la barre des tâches
4. Vérification immédiate au démarrage

### Scénario 4 : Désinstallation
1. Lancer le désinstalleur depuis le menu Démarrer
2. L'updater devrait s'arrêter automatiquement
3. VanadielXI_Updater.exe supprimé
4. Clé de registre de démarrage automatique supprimée

---

## Débogage des problèmes courants

### Problème : Le serveur ne répond pas
```bash
# Vérifier nginx
systemctl status nginx

# Vérifier PHP-FPM
systemctl status php8.4-fpm

# Vérifier les logs
tail -f /var/log/nginx/updates_error.log
```

### Problème : Les fichiers ne se téléchargent pas
```bash
# Vérifier les permissions
ls -la /var/www/html/updates/files/ROM/24/

# Devrait être : -rw-r--r-- www-data www-data
# Si non, corriger :
chmod 644 /var/www/html/updates/files/ROM/24/*.DAT
chown www-data:www-data /var/www/html/updates/files/ROM/24/*.DAT
```

### Problème : L'updater ne démarre pas
1. Vérifier que .NET 6.0 est installé sur Windows
2. Vérifier les logs : `%TEMP%\VanadielXI_Updater.log`
3. Lancer depuis la ligne de commande pour voir les erreurs :
   ```cmd
   "C:\Program Files\PlayOnline\VanadielXI_Updater.exe"
   ```

### Problème : Pas de notification de mise à jour
1. Vérifier que la version serveur est différente
2. Vérifier les logs client
3. Forcer une vérification manuelle (clic droit → Vérifier)
4. Vérifier la connectivité :
   ```cmd
   ping vanadielxi-updates.duckdns.org
   curl https://vanadielxi-updates.duckdns.org/update_server.php?action=check_version
   ```

---

## Checklist finale avant déploiement

### Serveur :
- [ ] nginx fonctionne
- [ ] PHP-FPM fonctionne
- [ ] SSL certificat valide (note A)
- [ ] version.txt contient la bonne version
- [ ] update_manifest.txt contient tous les fichiers
- [ ] Permissions correctes sur files/ROM/**/*.DAT
- [ ] API accessible depuis l'extérieur

### Client :
- [ ] VanadielXI_Updater.exe compilé
- [ ] Script NSIS modifié
- [ ] Installeur NSIS compile correctement
- [ ] Test d'installation sur machine propre
- [ ] Updater se lance au démarrage
- [ ] Vérification automatique fonctionne
- [ ] Téléchargement fonctionne
- [ ] Désinstallation propre

---

**Tout est prêt pour le déploiement ! 🚀**
