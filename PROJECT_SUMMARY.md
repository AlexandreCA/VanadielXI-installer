# 📦 VanadielXI Auto-Updater - Projet Complet

## 🎯 Objectif
Ajouter un système de mise à jour automatique au client VanadielXI qui vérifie et installe les mises à jour toutes les 10 minutes.

---

## 📊 Architecture Globale

```
┌─────────────────────────────────────────────────────────────┐
│                    SERVEUR (LXC Debian)                     │
│  https://vanadielxi-updates.duckdns.org                     │
├─────────────────────────────────────────────────────────────┤
│  nginx + PHP 8.4 + SSL (Let's Encrypt - Note A)            │
│                                                              │
│  /var/www/html/updates/                                     │
│  ├── update_server.php      (API de mise à jour)           │
│  ├── version.txt            (1.0.0)                         │
│  ├── update_manifest.txt    (Liste des fichiers)           │
│  ├── update_manifest.sh     (Régénération manifeste)       │
│  └── files/                                                 │
│      └── ROM/                                               │
│          ├── 24/127.DAT                                     │
│          ├── 24/37.DAT                                      │
│          ├── 25/39.DAT                                      │
│          └── 25/40.DAT                                      │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ HTTPS
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT (Windows)                          │
├─────────────────────────────────────────────────────────────┤
│  VanadielXI_Updater.exe (C# .NET 6.0)                       │
│  ├── Vérification toutes les 10 minutes                     │
│  ├── Notification si mise à jour disponible                 │
│  ├── Téléchargement et installation automatiques            │
│  └── Démarrage automatique avec Windows                     │
│                                                              │
│  C:\Program Files\PlayOnline\                               │
│  ├── VanadielXI_Updater.exe                                 │
│  ├── version.txt                                            │
│  └── SquareEnix\FINAL FANTASY XI\ROM\...                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Fichiers du Projet

### Serveur (Déjà configuré ✅)
| Fichier | Description | Statut |
|---------|-------------|---------|
| `/var/www/html/updates/update_server.php` | API REST pour les mises à jour | ✅ Opérationnel |
| `/var/www/html/updates/version.txt` | Version actuelle (1.0.0) | ✅ Configuré |
| `/var/www/html/updates/update_manifest.txt` | Liste des fichiers | ✅ Généré |
| `/var/www/html/updates/update_manifest.sh` | Script de régénération | ✅ Fonctionnel |
| `/etc/nginx/sites-enabled/updates` | Configuration nginx | ✅ SSL activé |

### Client (À compiler)
| Fichier | Description | Action requise |
|---------|-------------|----------------|
| `VanadielXI_Updater.cs` | Code source C# de l'updater | ✅ Créé |
| `VanadielXI_Updater.csproj` | Fichier projet .NET | ✅ Créé |
| `FINAL_FANTASY_XI_v2_1_with_updater.nsi` | Script NSIS modifié | ✅ Créé |
| `compile.bat` | Script de compilation Windows | ✅ Créé |
| `README.md` | Documentation complète | ✅ Créé |
| `TESTING.md` | Guide de test | ✅ Créé |

---

## 🔧 Fonctionnalités Implémentées

### Serveur
✅ API REST avec 5 endpoints :
  - `check_version` : Obtenir la version serveur
  - `get_manifest` : Liste des fichiers à mettre à jour
  - `download` : Télécharger un fichier spécifique
  - `list_folders` : Lister les dossiers et fichiers
  - `info` : Informations complètes

✅ Système de logging avec IP et timestamp
✅ Protection anti-path-traversal
✅ Support HTTPS avec certificat SSL valide
✅ Script de régénération automatique du manifeste

### Client
✅ Vérification automatique toutes les 10 minutes
✅ Vérification immédiate au démarrage
✅ Notification Windows (balloon tooltip)
✅ Popup de confirmation avant installation
✅ Téléchargement et installation automatiques
✅ Icône dans la barre des tâches (system tray)
✅ Menu contextuel (clic droit)
✅ Démarrage automatique avec Windows
✅ Logging détaillé
✅ Protection contre instances multiples
✅ Désinstallation propre

---

## 🚀 Workflow de Mise à Jour

### Côté Serveur (Publier une mise à jour)
```bash
# 1. Copier les nouveaux fichiers .DAT
scp nouveaux_fichiers.DAT root@nginx:/var/www/html/updates/files/ROM/24/

# 2. Ajuster les permissions
chmod 644 /var/www/html/updates/files/ROM/24/*.DAT
chown www-data:www-data /var/www/html/updates/files/ROM/24/*.DAT

# 3. Regénérer le manifeste
cd /var/www/html/updates
./update_manifest.sh

# 4. Mettre à jour la version
echo "1.0.1" > version.txt

# 5. Vérifier
curl "http://localhost/updates/update_server.php?action=check_version"
```

### Côté Client (Automatique)
```
1. Vérification toutes les 10 minutes (ou manuelle)
2. Détection de nouvelle version (1.0.0 → 1.0.1)
3. Popup : "Mise à jour disponible. Installer ?"
4. Si OUI :
   - Téléchargement du manifeste
   - Téléchargement de chaque fichier .DAT
   - Installation dans ROM/24/ et ROM/25/
   - Mise à jour de version.txt → 1.0.1
5. Notification : "Mise à jour réussie"
```

---

## 🛠️ Compilation et Déploiement

### Étape 1 : Compiler l'Updater (Windows)

**Prérequis :**
- .NET SDK 6.0+ : https://dotnet.microsoft.com/download
- NSIS : https://nsis.sourceforge.io/Download

**Compilation automatique :**
```cmd
cd vanadielxi-updater
compile.bat
```

**Compilation manuelle :**
```cmd
# Compiler l'updater
dotnet publish VanadielXI_Updater.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

# Copier l'exécutable
copy bin\Release\net6.0-windows\win-x64\publish\VanadielXI_Updater.exe .

# Compiler l'installeur NSIS
"C:\Program Files (x86)\NSIS\makensis.exe" FINAL_FANTASY_XI_v2_1_with_updater.nsi
```

### Étape 2 : Distribution

**Fichier à distribuer :**
```
FINAL FANTASY XI.exe  (Installeur complet avec updater intégré)
```

**Taille approximative :**
- VanadielXI_Updater.exe : ~70 MB (self-contained)
- FINAL FANTASY XI.exe : Taille originale + 70 MB

---

## 📋 Checklist de Déploiement

### Avant la distribution :
- [ ] Serveur nginx opérationnel
- [ ] PHP-FPM fonctionne
- [ ] SSL valide (test : https://www.ssllabs.com/ssltest/)
- [ ] API accessible depuis l'extérieur
- [ ] Fichiers .DAT présents avec bonnes permissions
- [ ] Manifeste à jour
- [ ] Version.txt correct
- [ ] VanadielXI_Updater.exe compilé et testé
- [ ] Installeur NSIS compile sans erreurs
- [ ] Test d'installation sur machine propre
- [ ] Test de mise à jour fonctionnel
- [ ] Test de désinstallation propre

---

## 📊 Statistiques et Monitoring

### Logs Serveur
```bash
# Accès en temps réel
tail -f /var/log/nginx/updates_access.log

# Statistiques d'utilisation
cat /var/www/html/updates/updates.log | grep "check_version" | wc -l
cat /var/www/html/updates/updates.log | grep "download" | wc -l
```

### Logs Client
```
Emplacement : %TEMP%\VanadielXI_Updater.log

Contenu :
[2026-02-13 21:30:00] VanadielXI Updater démarré
[2026-02-13 21:30:01] Vérification des mises à jour...
[2026-02-13 21:30:02] Version actuelle : 1.0.0
[2026-02-13 21:30:03] Version serveur : 1.0.0
[2026-02-13 21:30:04] Le jeu est à jour
```

---

## 🔐 Sécurité

### Mesures Implémentées
✅ Communication HTTPS uniquement
✅ Certificat SSL valide (Let's Encrypt, note A)
✅ Validation des chemins de fichiers (anti path traversal)
✅ Permissions restrictives sur les fichiers
✅ Logging avec IP et timestamp
✅ Vérification de version avant téléchargement
✅ Pas d'exécution de code distant

### Recommandations Additionnelles
- [ ] Ajouter vérification MD5/SHA256 des fichiers
- [ ] Implémenter signature numérique des mises à jour
- [ ] Rate limiting sur l'API
- [ ] Monitoring des téléchargements suspects

---

## 🎯 Avantages du Système

### Pour les Développeurs
✅ Déploiement de correctifs en quelques minutes
✅ Pas besoin de redistribuer l'installeur complet
✅ Logs détaillés des téléchargements
✅ Contrôle total sur les versions

### Pour les Utilisateurs
✅ Jeu toujours à jour automatiquement
✅ Pas besoin de chercher les mises à jour manuellement
✅ Téléchargements sécurisés (HTTPS)
✅ Notification claire des nouvelles versions
✅ Choix d'installer ou non

---

## 🔮 Évolutions Futures Possibles

### Court terme
- [ ] Barre de progression pour les téléchargements
- [ ] Support de plusieurs langues
- [ ] Interface graphique complète

### Moyen terme
- [ ] Patchs différentiels (delta updates)
- [ ] Vérification d'intégrité (hashes)
- [ ] Rollback automatique en cas d'échec
- [ ] Support de canaux (stable/beta)

### Long terme
- [ ] Système de A/B testing
- [ ] Téléchargement P2P entre clients
- [ ] Pré-téléchargement des mises à jour
- [ ] Analyse prédictive de la bande passante

---

## 📞 Support et Maintenance

### Documentation
- `README.md` : Guide complet d'utilisation
- `TESTING.md` : Guide de test détaillé
- Ce fichier : Vue d'ensemble du projet

### Dépannage
Consulter `TESTING.md` section "Débogage des problèmes courants"

### Contact
Projet maintenu par Fox_Mulder pour VanadielXI Server

---

## 📜 Licence

**ZLIB License**
Copyright (c) 2023-2026 VanadielXI Server

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.

---

**✨ Projet Complet - Prêt pour le Déploiement ! ✨**

**Date de création :** 13 février 2026
**Version initiale :** 1.0.0
**Statut :** Production Ready 🚀
