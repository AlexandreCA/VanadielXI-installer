# 🚀 DÉMARRAGE RAPIDE - VanadielXI Auto-Updater

## ✅ Votre serveur est déjà configuré !

Votre serveur nginx sur LXC Debian est **100% opérationnel** avec :
- ✅ HTTPS activé (SSL note A)
- ✅ API de mise à jour fonctionnelle
- ✅ Fichiers .DAT en place
- ✅ Système de versioning prêt

**URL du serveur :** `https://vanadielxi-updates.duckdns.org`

---

## 🎯 Prochaines Étapes

### 1️⃣ Sur votre PC Windows

**Télécharger et extraire le projet :**
- Extraire `VanadielXI-AutoUpdater-Complete.zip`
- Aller dans le dossier `vanadielxi-updater`

**Installer les prérequis :**
1. **.NET SDK 6.0** : https://dotnet.microsoft.com/download
2. **NSIS** : https://nsis.sourceforge.io/Download

**Compiler le projet :**
```cmd
# Option facile : double-cliquer sur
compile.bat

# OU manuellement :
dotnet publish VanadielXI_Updater.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

### 2️⃣ Compiler l'installeur NSIS

**Fichiers nécessaires :**
Vous devez avoir dans le même dossier que le script NSIS :
- ✅ `VanadielXI_Updater.exe` (compilé à l'étape 1)
- ⚠️ Tous vos fichiers originaux NSIS :
  - `installer.ico`
  - `background.bmp`
  - `license.txt`
  - `data.pak` (archive du jeu)
  - `hd_pack.pak` (pack HD optionnel - voir ci-dessous)
  - `VS2010.exe`, `VS2012.exe`, etc. (dépendances)

### 📦 Pack HD Optionnel

L'installeur propose maintenant d'installer un pack HD (textures haute résolution).

**Pour activer cette fonctionnalité :**

1. **Créer le fichier `hd_pack.pak`** avec vos textures HD
   ```cmd
   # Exemple avec 7-Zip
   7z a -t7z hd_pack.pak HD_Textures\*
   ```

2. **Placer `hd_pack.pak`** dans le même dossier que `data.pak`

3. **Lors de l'installation**, une page demandera :
   ```
   ☑ Installer le Pack HD (recommandé)
   ```

**Si vous n'avez pas de pack HD :**
- Pas de problème ! L'installeur fonctionnera normalement
- La case à cocher s'affichera quand même
- Si cochée mais fichier absent → Message d'avertissement et continue

**Compiler :**
```cmd
"C:\Program Files (x86)\NSIS\makensis.exe" FINAL_FANTASY_XI_v2_1_with_updater.nsi
```

**Résultat :** `FINAL FANTASY XI.exe` (installeur complet avec updater)

### 3️⃣ Tester

**Installation :**
1. Lancer `FINAL FANTASY XI.exe`
2. Suivre les étapes d'installation
3. À la fin, `VanadielXI_Updater.exe` se lance automatiquement
4. Une icône apparaît dans la barre des tâches

**Tester la mise à jour :**
1. Sur le serveur : `echo "1.0.1" > /var/www/html/updates/version.txt`
2. Sur le client : Clic droit sur l'icône → "Vérifier les mises à jour"
3. Une popup devrait apparaître !

---

## 📝 Documentation Complète

- **README.md** : Guide complet avec tous les détails
- **TESTING.md** : Guide de test étape par étape
- **PROJECT_SUMMARY.md** : Vue d'ensemble du projet

---

## 🔧 Publier une Mise à Jour (Serveur)

```bash
# 1. Copier vos nouveaux fichiers .DAT
scp nouveaux_fichiers.DAT root@nginx:/var/www/html/updates/files/ROM/24/

# 2. SSH vers le serveur
ssh root@nginx

# 3. Ajuster les permissions
cd /var/www/html/updates
chmod 644 files/ROM/24/*.DAT
chown www-data:www-data files/ROM/24/*.DAT

# 4. Regénérer le manifeste
./update_manifest.sh

# 5. Mettre à jour la version
echo "1.0.1" > version.txt

# 6. Vérifier
curl "http://localhost/updates/update_server.php?action=check_version"
```

**🎉 Dans les 10 minutes, tous vos joueurs seront notifiés !**

---

## ❓ Questions Fréquentes

**Q: Combien de temps prend la vérification ?**
R: Toutes les 10 minutes, silencieusement en arrière-plan.

**Q: Les joueurs peuvent-ils refuser la mise à jour ?**
R: Oui, une popup demande confirmation avant d'installer.

**Q: Comment changer l'intervalle de vérification ?**
R: Modifier la ligne 21 dans `VanadielXI_Updater.cs` puis recompiler.

**Q: L'updater fonctionne sur quel Windows ?**
R: Windows 7 SP1 et supérieur (avec .NET 6.0).

---

## 🆘 Besoin d'Aide ?

1. Consulter `TESTING.md` pour le débogage
2. Vérifier les logs :
   - Client : `%TEMP%\VanadielXI_Updater.log`
   - Serveur : `/var/www/html/updates/updates.log`

---

**✨ Tout est prêt ! Bon déploiement ! 🚀**
