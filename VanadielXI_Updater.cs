using System;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Diagnostics;
using Microsoft.Win32;
using System.Security.Cryptography;
using System.Text;

namespace VanadielXI_Updater
{
    class Program
    {
        // MODIFIÉ: Utiliser HTTP pour le serveur public en attendant SSL
        private static readonly string UPDATE_SERVER_PUBLIC = "https://boxproton.org/update_server.php";
        private static readonly string UPDATE_SERVER_LOCAL = "http://192.168.1.17/updates/update_server.php";
        private static string UPDATE_SERVER = ""; // Sera déterminé automatiquement
        
        private static readonly string INSTALL_PATH = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "PlayOnline");
        private static readonly string VERSION_FILE = Path.Combine(INSTALL_PATH, "version.txt");
        private static readonly string LOG_FILE = Path.Combine(Path.GetTempPath(), "VanadielXI_Updater.log");
        private static readonly int CHECK_INTERVAL_MINUTES = 10;
        
        private static HttpClient httpClient = new HttpClient() { Timeout = TimeSpan.FromSeconds(30) }; // MODIFIÉ: Timeout plus long
        private static NotifyIcon trayIcon;
        private static bool isUpdating = false;

        [STAThread]
        static void Main(string[] args)
        {
            // Vérifier si déjà en cours d'exécution
            if (IsAlreadyRunning())
            {
                Log("L'updater est déjà en cours d'exécution. Fermeture...");
                return;
            }

            // Détecter le meilleur serveur au démarrage
            DetectBestServer();

            // Créer l'icône de notification
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            
            trayIcon = new NotifyIcon
            {
                Icon = System.Drawing.SystemIcons.Application,
                Visible = true,
                Text = "VanadielXI Updater"
            };

            var contextMenu = new ContextMenuStrip();
            contextMenu.Items.Add("Vérifier les mises à jour", null, (s, e) => Task.Run(() => CheckForUpdates(true)));
            contextMenu.Items.Add("Quitter", null, (s, e) => Application.Exit());
            trayIcon.ContextMenuStrip = contextMenu;

            Log("VanadielXI Updater démarré");
            ShowNotification("VanadielXI Updater", "Le service de mise à jour est actif", ToolTipIcon.Info);

            // Vérifier immédiatement au démarrage
            Task.Run(() => CheckForUpdates(false));

            // Timer pour vérifier toutes les 10 minutes
            var timer = new System.Windows.Forms.Timer();
            timer.Interval = CHECK_INTERVAL_MINUTES * 60 * 1000; // 10 minutes en millisecondes
            timer.Tick += (s, e) => Task.Run(() => CheckForUpdates(false));
            timer.Start();

            Application.Run();
        }

        private static async Task CheckForUpdates(bool manualCheck)
        {
            if (isUpdating)
            {
                Log("Une mise à jour est déjà en cours...");
                return;
            }

            try
            {
                isUpdating = true;
                Log("Vérification des mises à jour...");

                // Obtenir la version actuelle
                string currentVersion = GetCurrentVersion();
                Log($"Version actuelle : {currentVersion}");

                // Vérifier la version serveur
                var serverVersion = await GetServerVersion();
                if (serverVersion == null)
                {
                    Log("Impossible de contacter le serveur de mise à jour");
                    if (manualCheck)
                        ShowNotification("Erreur", "Impossible de contacter le serveur", ToolTipIcon.Error);
                    return;
                }

                Log($"Version serveur : {serverVersion}");

                // Comparer les versions
                if (serverVersion == currentVersion)
                {
                    Log("Le jeu est à jour");
                    if (manualCheck)
                        ShowNotification("À jour", "Aucune mise à jour disponible", ToolTipIcon.Info);
                    return;
                }

                // Nouvelle version disponible
                Log($"Nouvelle version disponible : {serverVersion}");
                
                // Demander confirmation à l'utilisateur
                DialogResult result = MessageBox.Show(
                    $"Une nouvelle mise à jour est disponible !\n\n" +
                    $"Version actuelle : {currentVersion}\n" +
                    $"Nouvelle version : {serverVersion}\n\n" +
                    $"Voulez-vous installer cette mise à jour maintenant ?",
                    "Mise à jour disponible",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question
                );

                if (result == DialogResult.Yes)
                {
                    await PerformUpdate(serverVersion);
                }
                else
                {
                    Log("Mise à jour reportée par l'utilisateur");
                }
            }
            catch (Exception ex)
            {
                Log($"Erreur lors de la vérification : {ex.Message}");
                if (manualCheck)
                    ShowNotification("Erreur", $"Erreur : {ex.Message}", ToolTipIcon.Error);
            }
            finally
            {
                isUpdating = false;
            }
        }

        private static async Task PerformUpdate(string newVersion)
        {
            try
            {
                Log("Début de la mise à jour...");
                ShowNotification("Mise à jour", "Téléchargement en cours...", ToolTipIcon.Info);

                // Obtenir le manifeste (liste des fichiers)
                var manifest = await GetManifest();
                if (manifest == null || manifest.files == null)
                {
                    throw new Exception("Impossible d'obtenir la liste des fichiers");
                }

                Log($"Fichiers à télécharger : {manifest.files.Length}");

                int downloadedCount = 0;
                int totalFiles = manifest.files.Length;

                // Télécharger chaque fichier
                foreach (var file in manifest.files)
                {
                    downloadedCount++;
                    Log($"Téléchargement {downloadedCount}/{totalFiles} : {file}");
                    
                    bool success = await DownloadFile(file);
                    if (!success)
                    {
                        throw new Exception($"Échec du téléchargement de {file}");
                    }
                }

                // Mettre à jour le fichier de version
                File.WriteAllText(VERSION_FILE, newVersion);
                
                Log($"Mise à jour terminée avec succès ! Version {newVersion}");
                ShowNotification("Mise à jour réussie", $"VanadielXI a été mis à jour vers la version {newVersion}", ToolTipIcon.Info);

                // Demander si on doit redémarrer le jeu
                DialogResult restart = MessageBox.Show(
                    "La mise à jour a été installée avec succès.\n\n" +
                    "Si le jeu est en cours d'exécution, vous devrez le redémarrer pour appliquer les changements.",
                    "Mise à jour terminée",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
            }
            catch (Exception ex)
            {
                Log($"Erreur lors de la mise à jour : {ex.Message}");
                ShowNotification("Erreur de mise à jour", ex.Message, ToolTipIcon.Error);
            }
        }

        private static async Task<string> GetServerVersion()
        {
            try
            {
                var response = await httpClient.GetStringAsync($"{UPDATE_SERVER}?action=check_version");
                var json = JsonSerializer.Deserialize<JsonElement>(response);
                
                if (json.GetProperty("success").GetBoolean())
                {
                    return json.GetProperty("version").GetString();
                }
            }
            catch (Exception ex)
            {
                Log($"Erreur GetServerVersion avec {UPDATE_SERVER}: {ex.Message}");
                
                // Tenter un fallback sur l'autre serveur
                string fallbackServer = (UPDATE_SERVER == UPDATE_SERVER_LOCAL) ? UPDATE_SERVER_PUBLIC : UPDATE_SERVER_LOCAL;
                
                try
                {
                    Log($"Tentative de fallback sur {fallbackServer}...");
                    var response = await httpClient.GetStringAsync($"{fallbackServer}?action=check_version");
                    var json = JsonSerializer.Deserialize<JsonElement>(response);
                    
                    if (json.GetProperty("success").GetBoolean())
                    {
                        // Basculer sur ce serveur pour les prochaines fois
                        UPDATE_SERVER = fallbackServer;
                        Log($"✓ Basculé sur {fallbackServer}");
                        return json.GetProperty("version").GetString();
                    }
                }
                catch (Exception ex2)
                {
                    Log($"Erreur fallback : {ex2.Message}");
                }
            }
            return null;
        }

        private static async Task<ManifestResponse> GetManifest()
        {
            try
            {
                var response = await httpClient.GetStringAsync($"{UPDATE_SERVER}?action=get_manifest");
                return JsonSerializer.Deserialize<ManifestResponse>(response);
            }
            catch (Exception ex)
            {
                Log($"Erreur GetManifest : {ex.Message}");
                return null;
            }
        }

        private static async Task<bool> DownloadFile(string filename)
        {
            try
            {
                string url = $"{UPDATE_SERVER}?action=download&file={Uri.EscapeDataString(filename)}";
                
                // MODIFIÉ: Chemin correct pour les fichiers ROM
                // Le filename contient déjà le chemin complet (ex: "ROM/24/127.DAT")
                string localPath = Path.Combine(INSTALL_PATH, "SquareEnix", "FINAL FANTASY XI", filename);
                
                // Créer le dossier si nécessaire
                string directory = Path.GetDirectoryName(localPath);
                if (!Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                    Log($"Création du répertoire : {directory}");
                }

                // Télécharger le fichier
                var fileBytes = await httpClient.GetByteArrayAsync(url);
                
                // Sauvegarder
                File.WriteAllBytes(localPath, fileBytes);
                
                Log($"Fichier téléchargé : {filename} ({fileBytes.Length} octets) -> {localPath}");
                return true;
            }
            catch (Exception ex)
            {
                Log($"Erreur téléchargement {filename} : {ex.Message}");
                return false;
            }
        }

        private static string GetCurrentVersion()
        {
            try
            {
                if (File.Exists(VERSION_FILE))
                {
                    return File.ReadAllText(VERSION_FILE).Trim();
                }
            }
            catch { }
            
            return "0.0.0"; // Version par défaut si fichier absent
        }

        private static void ShowNotification(string title, string message, ToolTipIcon icon)
        {
            if (trayIcon != null)
            {
                trayIcon.ShowBalloonTip(5000, title, message, icon);
            }
        }

        private static void Log(string message)
        {
            try
            {
                string logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
                File.AppendAllText(LOG_FILE, logEntry + Environment.NewLine);
                Console.WriteLine(logEntry);
            }
            catch { }
        }

        private static bool IsAlreadyRunning()
        {
            string processName = Process.GetCurrentProcess().ProcessName;
            Process[] processes = Process.GetProcessesByName(processName);
            return processes.Length > 1;
        }

        private static void DetectBestServer()
        {
            Log("Détection du meilleur serveur...");
            
            // Essayer d'abord le serveur local (plus rapide)
            if (TestServer(UPDATE_SERVER_LOCAL))
            {
                UPDATE_SERVER = UPDATE_SERVER_LOCAL;
                Log($"✓ Serveur local détecté et utilisé : {UPDATE_SERVER_LOCAL}");
                return;
            }
            
            // Sinon, utiliser le serveur public
            if (TestServer(UPDATE_SERVER_PUBLIC))
            {
                UPDATE_SERVER = UPDATE_SERVER_PUBLIC;
                Log($"✓ Serveur public utilisé : {UPDATE_SERVER_PUBLIC}");
                return;
            }
            
            // Par défaut, utiliser le serveur public
            UPDATE_SERVER = UPDATE_SERVER_PUBLIC;
            Log($"⚠ Aucun serveur accessible, utilisation par défaut : {UPDATE_SERVER_PUBLIC}");
        }

        private static bool TestServer(string serverUrl)
        {
            try
            {
                var task = httpClient.GetStringAsync($"{serverUrl}?action=check_version");
                task.Wait(3000); // Timeout de 3 secondes
                
                if (task.IsCompleted && !task.IsFaulted)
                {
                    var response = task.Result;
                    return response.Contains("\"success\":true");
                }
            }
            catch (Exception ex)
            {
                Log($"Échec de connexion à {serverUrl}: {ex.Message}");
            }
            
            return false;
        }

        // Classes pour la désérialisation JSON
        private class ManifestResponse
        {
            public bool success { get; set; }
            public string[] files { get; set; }
            public int count { get; set; }
        }
    }
}
