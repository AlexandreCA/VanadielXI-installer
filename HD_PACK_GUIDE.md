# 🎨 Guide du Pack HD - VanadielXI Auto-Updater

## Vue d'ensemble

L'installeur VanadielXI supporte maintenant un **Pack HD optionnel** qui permet d'installer des textures haute résolution pour améliorer la qualité graphique du jeu.

---

## 📦 Qu'est-ce que le Pack HD ?

Le Pack HD est une archive (`hd_pack.pak`) contenant :
- Textures haute résolution (2K, 4K)
- Modèles 3D améliorés
- Effets visuels de meilleure qualité
- Tout contenu graphique amélioré

**Avantages :**
✅ Meilleure qualité visuelle
✅ Installation optionnelle (l'utilisateur choisit)
✅ Peut être installé/désinstallé facilement
✅ Compatible avec les mises à jour automatiques

---

## 🛠️ Créer le Pack HD

### Méthode 1 : Avec 7-Zip (Recommandé)

**Étape 1 : Préparer vos fichiers**
```
HD_Textures/
├── ROM/
│   ├── 0/
│   │   └── texture_001.dat
│   ├── 1/
│   │   └── texture_002.dat
│   └── ...
└── autres_fichiers/
```

**Étape 2 : Créer l'archive**
```cmd
# Ouvrir PowerShell ou CMD
cd C:\chemin\vers\vos\fichiers

# Créer le pack HD avec compression maximale
7z a -t7z -mx=9 hd_pack.pak HD_Textures\*

# OU avec compression normale (plus rapide)
7z a -t7z hd_pack.pak HD_Textures\*
```

**Étape 3 : Vérifier**
```cmd
# Voir le contenu
7z l hd_pack.pak

# Tester l'intégrité
7z t hd_pack.pak
```

### Méthode 2 : Avec NSIS (Pendant la compilation)

Si vous voulez intégrer directement dans l'installeur :

**Modifier le script NSIS :**
```nsis
Section "HD Pack" SecHDPack
  SetOutPath "$INSTDIR\SquareEnix\FINAL FANTASY XI"
  
  ; Extraction des fichiers HD
  File /r "HD_Textures\ROM\*.*"
  
  DetailPrint "HD Pack installed!"
SectionEnd
```

---

## 📋 Structure Recommandée du Pack HD

### Option A : Remplacement de Fichiers
Le pack HD écrase les fichiers existants avec des versions HD.

**Structure :**
```
hd_pack.pak
└── SquareEnix/
    └── FINAL FANTASY XI/
        └── ROM/
            ├── 0/
            │   └── 1.DAT (version HD)
            ├── 1/
            │   └── 2.DAT (version HD)
            └── ...
```

**Avantage :** Simple, fichiers directement remplacés
**Inconvénient :** Écrase les fichiers originaux

### Option B : Dossier Séparé
Le pack HD est dans un dossier séparé.

**Structure :**
```
hd_pack.pak
└── SquareEnix/
    └── FINAL FANTASY XI/
        └── HD_Textures/
            ├── characters/
            ├── environments/
            └── effects/
```

**Avantage :** Garde les fichiers originaux intacts
**Inconvénient :** Nécessite modification du client du jeu

---

## 🔧 Intégration dans l'Installeur

### Fichiers Nécessaires

Placez `hd_pack.pak` dans le même dossier que votre installeur NSIS :

```
C:\VotreDossier\
├── FINAL_FANTASY_XI_v2_1_with_updater.nsi
├── VanadielXI_Updater.exe
├── data.pak            ← Jeu de base
├── hd_pack.pak         ← Pack HD (nouveau)
├── installer.ico
└── ...
```

### Workflow d'Installation

**1. L'utilisateur lance l'installeur**
```
FINAL FANTASY XI.exe
```

**2. Page "Pack HD" s'affiche**
```
┌─────────────────────────────────────────┐
│  Installation du Pack HD (Optionnel)    │
├─────────────────────────────────────────┤
│                                         │
│  Le Pack HD améliore considérablement   │
│  la qualité graphique du jeu avec des   │
│  textures haute résolution.             │
│                                         │
│  Taille : environ 2-3 GB supplémentaires│
│                                         │
│  ☑ Installer le Pack HD (recommandé)   │
│                                         │
│  Note : Vous pouvez toujours installer  │
│  le Pack HD plus tard en relançant      │
│  l'installateur.                        │
└─────────────────────────────────────────┘
```

**3. Si coché → Installation du pack**
```
Installing game files... [████████████] 100%
Installing HD textures... [████████████] 100%
HD Pack installed successfully!
```

**4. Si NON coché → Skip**
```
Installing game files... [████████████] 100%
HD Pack installation skipped by user.
```

---

## 📊 Tailles Recommandées

### Pack HD Léger (500 MB - 1 GB)
- Textures UI en haute résolution
- Icônes d'objets améliorées
- Quelques modèles clés

**Bon pour :** Serveurs avec bande passante limitée

### Pack HD Standard (1-3 GB)
- Toutes les textures de personnages
- Textures d'environnement principales
- Effets visuels améliorés

**Bon pour :** Équilibre qualité/taille

### Pack HD Complet (3-10 GB)
- Toutes les textures en 4K
- Tous les modèles 3D améliorés
- Skybox haute résolution
- Tous les effets

**Bon pour :** Qualité maximale

---

## 🧪 Tester le Pack HD

### Test 1 : Vérifier l'archive
```cmd
7z t hd_pack.pak
```
Doit afficher : `Everything is Ok`

### Test 2 : Tester l'installation
```cmd
# Compiler l'installeur avec le pack HD
.\compile.bat

# Lancer l'installeur
.\FINAL FANTASY XI.exe

# Cocher "Installer le Pack HD"
# Vérifier dans les logs :
```

**Logs attendus :**
```
Installing game files... OK
Installing HD Pack...
Installing HD textures 1/150... 2/150... 
HD Pack installed successfully!
```

### Test 3 : Vérifier les fichiers installés
```cmd
dir "C:\Program Files\PlayOnline\SquareEnix\FINAL FANTASY XI\ROM"
```

Les fichiers HD devraient être présents.

---

## ⚠️ Important : Compression

### Formats Supportés
NSIS avec le plugin Nsis7z supporte :
- ✅ 7z (recommandé)
- ✅ ZIP
- ✅ TAR
- ❌ RAR (non supporté)

### Recommandations de Compression

**Pour distribution Internet :**
```cmd
# Compression maximale (lent mais petit)
7z a -t7z -mx=9 hd_pack.pak HD_Textures\*
```

**Pour distribution locale :**
```cmd
# Compression rapide
7z a -t7z -mx=3 hd_pack.pak HD_Textures\*
```

**Sans compression (testing) :**
```cmd
7z a -t7z -mx=0 hd_pack.pak HD_Textures\*
```

---

## 🔄 Mise à Jour du Pack HD

### Via l'Auto-Updater

Vous pouvez aussi mettre à jour le pack HD via le système de mise à jour automatique !

**Sur le serveur nginx :**
```bash
# Ajouter les nouveaux fichiers HD dans le manifeste
cd /var/www/html/updates/files/
mkdir -p HD
cp nouveaux_fichiers_hd.DAT HD/

# Regénérer le manifeste
cd /var/www/html/updates/
./update_manifest.sh

# Mettre à jour la version
echo "1.1.0" > version.txt
```

**Résultat :** Les clients téléchargeront automatiquement les nouvelles textures HD !

---

## 📝 Exemples de Contenu HD

### Textures de Personnages
```
ROM/1/character_face_hd.DAT
ROM/1/character_body_hd.DAT
ROM/1/character_hair_hd.DAT
```

### Textures d'Environnement
```
ROM/5/ground_grass_4k.DAT
ROM/5/ground_stone_4k.DAT
ROM/5/water_reflection_hd.DAT
```

### Effets Visuels
```
ROM/10/magic_fire_hd.DAT
ROM/10/magic_ice_hd.DAT
ROM/10/weapon_glow_hd.DAT
```

### UI et Menus
```
ROM/20/menu_background_hd.DAT
ROM/20/icons_items_hd.DAT
ROM/20/font_hd.DAT
```

---

## 🎯 Cas d'Usage

### Scénario 1 : Première Installation
**Utilisateur :** Nouveau joueur
**Action :** Coche le pack HD
**Résultat :** Jeu installé directement avec graphismes HD

### Scénario 2 : Installation Légère
**Utilisateur :** Connexion lente
**Action :** Décoche le pack HD
**Résultat :** Installation rapide, peut installer HD plus tard

### Scénario 3 : Mise à Jour
**Utilisateur :** Installation existante
**Action :** Relance l'installeur, choisit "Mise à jour uniquement"
**Résultat :** Peut ajouter le pack HD sans réinstaller le jeu

---

## 🛡️ Bonnes Pratiques

✅ **DO:**
- Compresser avec 7z pour meilleure compression
- Tester l'archive avant distribution
- Documenter le contenu du pack HD
- Fournir des captures d'écran avant/après
- Indiquer la taille exacte du pack

❌ **DON'T:**
- Ne pas créer un pack HD trop gros (>10 GB)
- Ne pas inclure de fichiers corrompus
- Ne pas oublier de tester l'installation
- Ne pas changer la structure sans documenter

---

## 📞 FAQ

**Q : Que se passe-t-il si `hd_pack.pak` est absent ?**
R : L'installeur affiche un avertissement et continue sans le pack HD.

**Q : Peut-on avoir plusieurs packs HD ?**
R : Oui ! Créez `hd_pack_characters.pak`, `hd_pack_environments.pak`, etc.
   Modifiez le script NSIS pour ajouter plusieurs cases à cocher.

**Q : Le pack HD ralentit-il le jeu ?**
R : Dépend du PC. Les textures HD utilisent plus de VRAM.

**Q : Peut-on désinstaller juste le pack HD ?**
R : Oui, créez un désinstalleur spécifique ou réinstallez sans cocher la case.

---

## 📄 Fichiers de Référence

- `FINAL_FANTASY_XI_v2_1_with_updater.nsi` : Script NSIS avec support Pack HD
- `QUICK_START.md` : Instructions de compilation avec Pack HD
- `README.md` : Documentation complète

---

**Le Pack HD est maintenant prêt à être utilisé ! 🎨**

**Taille recommandée :** 1-3 GB
**Format :** 7z (.pak)
**Emplacement :** Même dossier que data.pak
