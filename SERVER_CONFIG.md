# 🌐 Configuration des Serveurs - VanadielXI Auto-Updater

## Système de Détection Automatique

L'updater utilise un système intelligent de détection automatique :

1. **Au démarrage**, il teste d'abord le serveur LOCAL (réseau local)
2. Si le serveur local ne répond pas, il bascule sur le serveur PUBLIC (internet)
3. **En cas d'erreur** pendant une vérification, il essaie automatiquement l'autre serveur

**Avantages :**
- ✅ Performances optimales (serveur local plus rapide)
- ✅ Fonctionnement garanti (fallback automatique)
- ✅ Pas de configuration requise par l'utilisateur

---

## 🔧 Configuration des URLs de Serveur

### Fichier à modifier : `VanadielXI_Updater.cs`

**Lignes 18-19 :**
```csharp
private static readonly string UPDATE_SERVER_PUBLIC = "https://vanadielxi-updates.duckdns.org/update_server.php";
private static readonly string UPDATE_SERVER_LOCAL = "http://192.168.1.15/updates/update_server.php";
```

### Serveur PUBLIC (Internet)
**Par défaut :** `https://vanadielxi-updates.duckdns.org/update_server.php`

**Quand le modifier :**
- Si vous changez de nom de domaine
- Si vous migrez vers un autre serveur

**Exemple :**
```csharp
private static readonly string UPDATE_SERVER_PUBLIC = "https://mon-nouveau-serveur.com/api/updates.php";
```

### Serveur LOCAL (Réseau local)
**Par défaut :** `http://192.168.1.15/updates/update_server.php`

**À personnaliser avec :**
- L'adresse IP de votre serveur nginx LXC sur votre réseau local
- Le port si différent de 80 (ex: `http://192.168.1.15:8080/updates/update_server.php`)

**Comment trouver l'IP de votre serveur LXC :**
```bash
# Depuis le LXC nginx
ip addr show | grep "inet "
# Ou
hostname -I
```

**Exemple :**
```csharp
private static readonly string UPDATE_SERVER_LOCAL = "http://10.0.0.50/updates/update_server.php";
```

---

## 🎯 Scénarios d'Utilisation

### Scénario 1 : Serveur Local UNIQUEMENT (pas d'accès Internet)
```csharp
private static readonly string UPDATE_SERVER_PUBLIC = "http://192.168.1.15/updates/update_server.php";
private static readonly string UPDATE_SERVER_LOCAL = "http://192.168.1.15/updates/update_server.php";
```
Les deux pointent vers le même serveur local.

### Scénario 2 : Serveur Internet UNIQUEMENT (pas de serveur local)
```csharp
private static readonly string UPDATE_SERVER_PUBLIC = "https://vanadielxi-updates.duckdns.org/update_server.php";
private static readonly string UPDATE_SERVER_LOCAL = "https://vanadielxi-updates.duckdns.org/update_server.php";
```
Les deux pointent vers le serveur public.

### Scénario 3 : Hybride (recommandé - déjà configuré)
```csharp
private static readonly string UPDATE_SERVER_PUBLIC = "https://vanadielxi-updates.duckdns.org/update_server.php";
private static readonly string UPDATE_SERVER_LOCAL = "http://192.168.1.15/updates/update_server.php";
```
Serveur local pour les joueurs sur le LAN, serveur public pour les autres.

---

## 📊 Comment ça fonctionne

### Au Démarrage de l'Updater

```
1. Test du serveur LOCAL (http://192.168.1.15...)
   └─ Timeout : 3 secondes
   
2. Si succès → Utilise serveur LOCAL
   └─ Log : "✓ Serveur local détecté et utilisé"
   
3. Si échec → Test du serveur PUBLIC (https://vanadielxi-updates...)
   └─ Timeout : 3 secondes
   
4. Si succès → Utilise serveur PUBLIC
   └─ Log : "✓ Serveur public utilisé"
   
5. Si échec → Utilise serveur PUBLIC par défaut
   └─ Log : "⚠ Aucun serveur accessible, utilisation par défaut"
```

### Pendant les Vérifications

Si une erreur se produit (serveur inaccessible, timeout, etc.) :
```
1. Tentative avec le serveur actuellement configuré
2. Si échec → Essai automatique avec l'autre serveur (fallback)
3. Si succès → Bascule automatiquement sur ce serveur
   └─ Log : "✓ Basculé sur [nouveau serveur]"
```

**Exemple concret :**
- L'updater utilise le serveur local (192.168.1.15)
- Le joueur part en voyage (hors du réseau local)
- À la prochaine vérification, échec du serveur local
- Fallback automatique sur le serveur public (vanadielxi-updates.duckdns.org)
- Le joueur continue à recevoir les mises à jour !

---

## 🔍 Logs et Débogage

**Emplacement du log :**
```
C:\Users\<USERNAME>\AppData\Local\Temp\VanadielXI_Updater.log
```

**Exemple de log avec détection :**
```
[2026-02-13 22:00:00] VanadielXI Updater démarré
[2026-02-13 22:00:00] Détection du meilleur serveur...
[2026-02-13 22:00:01] ✓ Serveur local détecté et utilisé : http://192.168.1.15/updates/update_server.php
[2026-02-13 22:00:02] Vérification des mises à jour...
[2026-02-13 22:00:02] Version actuelle : 1.0.0
[2026-02-13 22:00:03] Version serveur : 1.0.0
[2026-02-13 22:00:03] Le jeu est à jour
```

**Exemple de log avec fallback :**
```
[2026-02-13 22:10:00] Vérification des mises à jour...
[2026-02-13 22:10:00] Erreur GetServerVersion avec http://192.168.1.15/updates/update_server.php: No connection could be made
[2026-02-13 22:10:00] Tentative de fallback sur https://vanadielxi-updates.duckdns.org/update_server.php...
[2026-02-13 22:10:02] ✓ Basculé sur https://vanadielxi-updates.duckdns.org/update_server.php
[2026-02-13 22:10:02] Version serveur : 1.0.1
```

---

## 🧪 Tester la Configuration

### Test 1 : Serveur local accessible
```powershell
# Depuis le PC client
curl http://192.168.1.15/updates/update_server.php?action=check_version
```
Devrait retourner : `{"success":true,"version":"1.0.0",...}`

### Test 2 : Serveur public accessible
```powershell
curl https://vanadielxi-updates.duckdns.org/update_server.php?action=check_version
```
Devrait retourner : `{"success":true,"version":"1.0.0",...}`

### Test 3 : Vérifier les logs de l'updater
```powershell
notepad %TEMP%\VanadielXI_Updater.log
```
Cherchez les lignes "Détection du meilleur serveur" et "Serveur détecté".

---

## ⚙️ Paramètres Avancés

### Timeout de connexion
**Fichier :** `VanadielXI_Updater.cs` ligne 27
```csharp
private static HttpClient httpClient = new HttpClient() { Timeout = TimeSpan.FromSeconds(5) };
```

**Valeur par défaut :** 5 secondes
**Recommandé :** 3-10 secondes

### Timeout de détection
**Fichier :** `VanadielXI_Updater.cs` ligne 297 (fonction TestServer)
```csharp
task.Wait(3000); // Timeout de 3 secondes
```

**Valeur par défaut :** 3000 ms (3 secondes)
**Recommandé :** 2000-5000 ms

---

## 🔐 Notes de Sécurité

**Serveur LOCAL (HTTP) :**
- ⚠️ Pas de chiffrement
- ✅ OK pour réseau local privé
- ❌ NE PAS exposer sur Internet

**Serveur PUBLIC (HTTPS) :**
- ✅ Chiffrement SSL/TLS
- ✅ Certificat valide (Let's Encrypt)
- ✅ Sécurisé pour Internet

**Recommandation :**
- LOCAL : toujours en HTTP (sauf si SSL configuré en local)
- PUBLIC : toujours en HTTPS

---

## 📞 Support

En cas de problème de connexion :
1. Vérifier les logs (`%TEMP%\VanadielXI_Updater.log`)
2. Tester manuellement les URLs avec curl/navigateur
3. Vérifier le pare-feu Windows
4. Vérifier que nginx tourne sur le serveur : `systemctl status nginx`

---

**Configuration actuelle :**
- 🌍 Serveur PUBLIC : `https://vanadielxi-updates.duckdns.org/update_server.php`
- 🏠 Serveur LOCAL : `http://192.168.1.15/updates/update_server.php`
- ⏱️ Timeout : 5 secondes
- 🔄 Fallback : Activé
- ✅ Détection automatique : Activée
