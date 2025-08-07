use anyhow::{Result, anyhow};
use chrono::Utc;
use regex::Regex;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::Duration;
use tokio::time::sleep;
use walkdir::WalkDir;

#[derive(Serialize, Deserialize, Debug)]
struct GitHubRelease {
    id: u64,
    tag_name: String,
    name: String,
    body: String,
    draft: bool,
    prerelease: bool,
    target_commitish: String,
}

#[derive(Serialize, Deserialize)]
struct CreateReleaseRequest {
    tag_name: String,
    target_commitish: String,
    name: String,
    body: String,
    draft: bool,
    prerelease: bool,
}

#[derive(Serialize, Deserialize)]
struct UpdateReleaseRequest {
    body: String,
}

struct EdgeUpdater {
    client: Client,
}

/// Compare two dotted-version strings (e.g. "110.0.1587.0") by numeric segments.
fn compare_versions(a: &str, b: &str) -> std::cmp::Ordering {
    let parse = |s: &str| {
        s.split('.')
            .map(|part| part.parse::<u64>().unwrap_or(0))
            .collect::<Vec<_>>()
    };
    let va = parse(a);
    let vb = parse(b);
    for (sa, sb) in va.iter().zip(vb.iter()) {
        match sa.cmp(sb) {
            std::cmp::Ordering::Equal => continue,
            non_eq => return non_eq,
        }
    }
    // all shared segments equal — shorter one is "less"
    va.len().cmp(&vb.len())
}

impl EdgeUpdater {
    fn new() -> Self {
        let client: Client = Client::new();
        Self { client }
    }

    async fn run(&self) -> Result<()> {
        println!(
            "Current username is: '{}'",
            std::env::var("USERNAME").unwrap_or_default()
        );

        // Download Edge Canary installer
        let edge_installer_path: PathBuf = self.download_edge_canary().await?;

        // Download strings64.exe
        let strings_exe_path: PathBuf = self.download_strings64().await?;

        // Install Edge Canary
        self.install_edge_canary(&edge_installer_path)?;

        // Wait for installation to complete
        let app_path: PathBuf = self.get_edge_app_path();
        self.wait_for_edge_installation(&app_path).await?;

        // Accept Strings64 EULA
        self.accept_strings_eula()?;

        // Find the latest Edge version
        let full_version: String = self.find_latest_edge_version(&app_path)?;
        let major_version: String = full_version.split('.').next().unwrap().to_string();
        let dll_path: PathBuf = app_path.join(&full_version).join("msedge.dll");

        println!("DLL PATH: {}", dll_path.display());

        // Create directory structure
        self.create_directory_structure(&major_version)?;

        // Check if build already exists
        if self.build_exists(&major_version, &full_version)? {
            println!("BUILD ALREADY EXISTS, EXITING.");
            return Ok(());
        }

        // Create new version directory
        self.create_version_directory(&major_version, &full_version)?;

        // Find previous version for comparison
        let (previous_full_version, previous_major_version): (String, String) =
            self.find_previous_version(&major_version)?;

        println!(
            "Comparing version: {} with version: {}",
            full_version, previous_full_version
        );

        // Extract features using strings64
        let current_features: HashSet<String> =
            self.extract_features(&strings_exe_path, &dll_path).await?;

        // Save current features
        self.save_features(
            &current_features,
            &major_version,
            &full_version,
            "original.txt",
        )?;

        // Load previous features
        let previous_features: HashSet<String> =
            self.load_previous_features(&previous_major_version, &previous_full_version)?;

        // Calculate differences
        let mut added: Vec<String> = current_features
            .iter()
            .filter(|feature| !previous_features.contains(*feature))
            .cloned()
            .collect();

        let mut removed: Vec<String> = previous_features
            .iter()
            .filter(|feature| !current_features.contains(*feature))
            .cloned()
            .collect();

        // Sort the results
        added.sort();
        removed.sort();

        // Save differences
        self.save_feature_list(&added, &major_version, &full_version, "added.txt")?;
        self.save_feature_list(&removed, &major_version, &full_version, "removed.txt")?;

        println!(
            "Added features ./Edge Canary/{}/{}/added.txt ({} entries)",
            major_version,
            full_version,
            added.len()
        );
        println!(
            "Removed features ./Edge Canary/{}/{}/removed.txt ({} entries)",
            major_version,
            full_version,
            removed.len()
        );

        // Update last.txt
        fs::write("last.txt", &full_version)?;

        // Update README
        self.update_readme(&full_version, &added)?;

        // Create Edge Canary shortcut maker
        self.create_shortcut_maker(&full_version, &added)?;

        // Commit and push changes
        self.commit_and_push()?;

        // Create GitHub release
        self.create_github_release(&full_version, &added, &removed)
            .await?;

        Ok(())
    }

    async fn download_edge_canary(&self) -> Result<PathBuf> {
        let url1: &str =
            "https://go.microsoft.com/fwlink/?linkid=2084706&Channel=Canary&language=en";
        let url2: &str = "https://c2rsetup.edog.officeapps.live.com/c2r/downloadEdge.aspx?platform=Default&source=EdgeInsiderPage&Channel=Canary&language=en";

        let temp_dir: PathBuf = std::env::temp_dir();
        let installer_path: PathBuf = temp_dir.join("MicrosoftEdgeSetupCanary.exe");

        println!("Downloading Edge Canary");

        // Try primary URL first
        println!("Trying the primary URL");
        let result: Result<(), anyhow::Error> = self.download_file(url1, &installer_path).await;

        if result.is_err() {
            println!("Downloading from the primary URL failed, trying the secondary URL");
            self.download_file(url2, &installer_path)
                .await
                .map_err(|_| anyhow!("Failed to download Edge from both URLs"))?;
        }

        Ok(installer_path)
    }

    async fn download_strings64(&self) -> Result<PathBuf> {
        let url: &str = "https://live.sysinternals.com/strings64.exe";
        let temp_dir: PathBuf = std::env::temp_dir();
        let strings_path: PathBuf = temp_dir.join("strings64.exe");

        println!("Downloading Strings64.exe");
        self.download_file(url, &strings_path)
            .await
            .map_err(|_| anyhow!("Failed to download Strings64"))?;

        Ok(strings_path)
    }

    async fn download_file(&self, url: &str, path: &Path) -> Result<()> {
        let response: reqwest::Response = self.client.get(url).send().await?;
        let bytes: bytes::Bytes = response.bytes().await?;
        std::fs::write(path, bytes)?;
        Ok(())
    }

    fn install_edge_canary(&self, installer_path: &Path) -> Result<()> {
        println!("Installing Edge Canary");
        Command::new(installer_path)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()?;
        Ok(())
    }

    fn get_edge_app_path(&self) -> PathBuf {
        let username: String = std::env::var("USERNAME").unwrap_or_default();
        PathBuf::from(format!(
            "C:\\Users\\{}\\AppData\\Local\\Microsoft\\Edge SxS\\Application",
            username
        ))
    }

    async fn wait_for_edge_installation(&self, app_path: &Path) -> Result<()> {
        println!("Waiting for Edge Canary to be downloaded and installed");

        let timeout: Duration = Duration::from_secs(60 * 60); // 60 minutes
        let start: std::time::Instant = std::time::Instant::now();

        loop {
            if start.elapsed() > timeout {
                return Err(anyhow!("Edge Canary installation failed - timeout"));
            }

            // Look for msedge.dll recursively
            if let Some(_) = WalkDir::new(app_path)
                .into_iter()
                .filter_map(|e| e.ok())
                .find(|entry| entry.file_name() == "msedge.dll")
            {
                println!("File found: Edge Canary installation completed");
                return Ok(());
            }

            println!("File not found. Waiting for 5 seconds...");
            sleep(Duration::from_secs(5)).await;
        }
    }

    fn accept_strings_eula(&self) -> Result<()> {
        println!("Accepting Strings64's EULA via Registry");

        #[cfg(windows)]
        {
            use winreg::RegKey;
            use winreg::enums::*;

            let hkcu: RegKey = RegKey::predef(HKEY_CURRENT_USER);
            let path: &str = "Software\\Sysinternals\\Strings";

            let key: RegKey = hkcu
                .create_subkey(path)
                .map_err(|e| anyhow!("Failed to create registry key: {}", e))?
                .0;

            key.set_value("EulaAccepted", &1u32)
                .map_err(|e| anyhow!("Failed to set registry value: {}", e))?;
        }

        Ok(())
    }

    fn find_latest_edge_version(&self, app_path: &Path) -> Result<String> {
        println!("Searching for the Edge Canary version that was just downloaded");

        // Collect all subdirs whose name starts with '1'
        let mut versions: Vec<String> = fs::read_dir(app_path)?
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().map(|ft| ft.is_dir()).unwrap_or(false))
            .map(|e| e.file_name().to_string_lossy().into_owned())
            .filter(|name| name.starts_with('1'))
            .collect();

        if versions.is_empty() {
            return Err(anyhow!("No Edge Canary version found"));
        }

        // Sort numerically by segments, then pick the last
        versions.sort_by(|a, b| compare_versions(a, b));
        Ok(versions.pop().unwrap())
    }

    fn create_directory_structure(&self, major_version: &str) -> Result<()> {
        let edge_canary_dir: PathBuf = PathBuf::from("Edge Canary");
        if !edge_canary_dir.exists() {
            fs::create_dir_all(&edge_canary_dir)?;
        }

        let major_version_dir: PathBuf = edge_canary_dir.join(major_version);
        if !major_version_dir.exists() {
            fs::create_dir_all(&major_version_dir)?;
        }

        Ok(())
    }

    fn build_exists(&self, major_version: &str, full_version: &str) -> Result<bool> {
        let version_dir: PathBuf = PathBuf::from("Edge Canary")
            .join(major_version)
            .join(full_version);

        if !version_dir.exists() {
            return Ok(false);
        }

        // Check if directory has any files
        let has_files: bool = fs::read_dir(&version_dir)?.next().is_some();

        Ok(has_files)
    }

    fn create_version_directory(&self, major_version: &str, full_version: &str) -> Result<()> {
        let version_dir: PathBuf = PathBuf::from("Edge Canary")
            .join(major_version)
            .join(full_version);

        fs::create_dir_all(&version_dir)?;
        Ok(())
    }

    fn find_previous_version(&self, current_major_version: &str) -> Result<(String, String)> {
        let base_dir = PathBuf::from("Edge Canary");
        let current_dir = base_dir.join(current_major_version);

        // 1) Collect all full-version folders in this major
        let mut versions: Vec<String> = fs::read_dir(&current_dir)?
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().map(|ft| ft.is_dir()).unwrap_or(false))
            .map(|e| e.file_name().to_string_lossy().into_owned())
            .collect();

        // If there are at least two, pick the second-to-last as "previous"
        if versions.len() >= 2 {
            // Sort ascending by numeric segments
            versions.sort_by(|a, b| compare_versions(a, b));
            // previous is the one right before the last
            let previous_full = versions[versions.len() - 2].clone();
            return Ok((previous_full, current_major_version.to_string()));
        }

        // 2) Otherwise, find the last version in the previous major
        // Gather all 3-digit major directories
        let mut majors: Vec<u32> = fs::read_dir(&base_dir)?
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().map(|ft| ft.is_dir()).unwrap_or(false))
            // bind the OsString first so to_string_lossy() can borrow from it safely
            .filter_map(|e| {
                let file_name_os: std::ffi::OsString = e.file_name();
                let name = file_name_os.to_string_lossy();
                if name.len() == 3 && name.chars().all(|c| c.is_ascii_digit()) {
                    name.parse().ok()
                } else {
                    None
                }
            })
            .collect();

        // Sort descending and skip the current major
        majors.sort_unstable();
        majors.reverse();
        for &maj in majors
            .iter()
            .skip_while(|&&m| m.to_string() == current_major_version)
        {
            let mut other_versions =
                self.get_versions_in_directory(&base_dir.join(maj.to_string()))?;
            if other_versions.is_empty() {
                continue;
            }
            other_versions.sort_by(|a, b| compare_versions(a, b));
            // newest from that major
            let prev_full = other_versions.pop().unwrap();
            return Ok((prev_full, maj.to_string()));
        }

        Err(anyhow!("No previous version found"))
    }

    fn get_versions_in_directory(&self, dir: &Path) -> Result<Vec<String>> {
        let mut versions: Vec<String> = Vec::new();

        if dir.exists() {
            for entry in fs::read_dir(dir)? {
                let entry = entry?;
                if entry.file_type()?.is_dir() {
                    versions.push(entry.file_name().to_string_lossy().to_string());
                }
            }
        }

        Ok(versions)
    }

    // Extract features: lines that begin with "ms" (case-Insensitive) followed by at least 4 more alphanumeric characters
    async fn extract_features(
        &self,
        strings_exe: &Path,
        dll_path: &Path,
    ) -> Result<HashSet<String>> {
        println!("Strings64 Running...");

        let output = Command::new(strings_exe).arg(dll_path).output()?;
        let stdout: String = String::from_utf8_lossy(&output.stdout).to_string();

        // Pattern: lines that start with "ms" (case-Insensitive) followed by at least 4 alphanumeric characters
        let regex: Regex = Regex::new(r"(?i)^ms[a-zA-Z0-9]{4,}$")?;

        let mut features: HashSet<String> = HashSet::new();

        // Process each line from strings64.exe output
        for line in stdout.lines() {
            // Check if line begins with "ms" (case-Insensitive) and has at least 4 more alphanumeric characters
            if regex.is_match(line) {
                features.insert(line.to_string());
            }
        }

        println!("Extracted {} features", features.len());
        Ok(features)
    }

    fn save_features(
        &self,
        features: &HashSet<String>,
        major_version: &str,
        full_version: &str,
        filename: &str,
    ) -> Result<()> {
        let file_path: PathBuf = PathBuf::from("Edge Canary")
            .join(major_version)
            .join(full_version)
            .join(filename);

        let mut sorted_features: Vec<&String> = features.iter().collect();
        sorted_features.sort();

        let content: String = sorted_features
            .into_iter()
            .map(|s| s.as_str())
            .collect::<Vec<&str>>()
            .join("\n");

        fs::write(&file_path, content)?;

        println!(
            "Saved: {} ({} entries)",
            file_path.display(),
            features.len()
        );
        Ok(())
    }

    fn save_feature_list(
        &self,
        features: &[String],
        major_version: &str,
        full_version: &str,
        filename: &str,
    ) -> Result<()> {
        let file_path: PathBuf = PathBuf::from("Edge Canary")
            .join(major_version)
            .join(full_version)
            .join(filename);

        // Don't sort here since we already sorted in the calling function
        let content: String = features.join("\n");

        fs::write(&file_path, content)?;
        Ok(())
    }

    // Load previous features - process lines the same way as extract_features
    fn load_previous_features(
        &self,
        previous_major_version: &str,
        previous_full_version: &str,
    ) -> Result<HashSet<String>> {
        let file_path: PathBuf = PathBuf::from("Edge Canary")
            .join(previous_major_version)
            .join(previous_full_version)
            .join("original.txt");

        let content: String = fs::read_to_string(file_path)?;

        // Process lines exactly the same way as extract_features
        let features: HashSet<String> = content
            .lines()
            .map(|line| line.to_string())
            .filter(|line| !line.is_empty())
            .collect();

        println!("Loaded {} previous features", features.len());
        Ok(features)
    }

    fn update_readme(&self, full_version: &str, added_features: &[String]) -> Result<()> {
        let readme_content: String = fs::read_to_string("README.md")?;

        let current_time: String = Utc::now().format("%m/%d/%Y %H:%M:%S").to_string();

        let added_list: String = added_features
            .iter()
            .map(|feature| format!("* {}\n", feature))
            .collect();

        let details_to_replace: String = format!(
            "\n### <a href=\"https://github.com/SpyNetGirl/MSEdgeFeatures\"><img width=\"35\" src=\"https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp\"></a> Latest Edge Canary version: {}\n\
            ### Last processed at: {} (UTC+00:00)\n\
            <details>\n\
            <summary>{} new features were added in the latest Edge Canary update</summary>\n\n\
            <br>\n\n\
            {}\
            </details>\n",
            full_version,
            current_time,
            added_features.len(),
            added_list
        );

        // Find the content between the start and end markers and replace it
        let start_marker: &str = "<!-- Edge-Canary-Version:START -->";
        let end_marker: &str = "<!-- Edge-Canary-Version:END -->";

        if let Some(start_pos) = readme_content.find(start_marker) {
            if let Some(end_pos) = readme_content.find(end_marker) {
                let start_index: usize = start_pos + start_marker.len();
                let before: &str = &readme_content[..start_index];
                let after: &str = &readme_content[end_pos..];
                let updated_content: String = format!("{}{}{}", before, details_to_replace, after);

                fs::write("README.md", updated_content.trim_end())?;
                return Ok(());
            }
        }

        Err(anyhow!(
            "Could not find the Edge Canary version markers in README.md"
        ))
    }

    fn create_shortcut_maker(&self, full_version: &str, added_features: &[String]) -> Result<()> {
        let features_string: String = added_features.join(",");
        let pre_arguments: String = format!(
            "--enable-features={}",
            features_string.trim_end_matches(',')
        );

        let content: String = format!(
            r#"
$FullVersionToUse = "{}"

$Arguments = "{}"

$content = @"
powershell.exe -WindowStyle hidden -Command "`$UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().user.value;`$UserName = (Get-LocalUser | where-object -FilterScript {{`$_.SID -eq `$UserSID}}).name;Get-Process | where-object -FilterScript {{`$_.path -eq \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`"}} | ForEach-Object -Process {{Stop-Process -Id `$_.id -Force -ErrorAction SilentlyContinue}};& \`"C:\Users\`$UserName\AppData\Local\Microsoft\Edge SxS\Application\msedge.exe\`" $Arguments"
"@

$content | Out-File -FilePath "C:\Users\$env:USERNAME\Downloads\EDGECAN Launcher $FullVersionToUse.bat"
"#,
            full_version, pre_arguments
        );

        fs::write("EdgeCanaryShortcutMaker.ps1", content)?;
        Ok(())
    }

    fn commit_and_push(&self) -> Result<()> {
        // Configure git
        Command::new("git")
            .args(["config", "--global", "user.email", "spynetgirl@outlook.com"])
            .output()?;

        Command::new("git")
            .args(["config", "--global", "user.name", "HotCakeX"])
            .output()?;

        // Add all changes
        Command::new("git").args(["add", "--all"]).output()?;

        // Commit changes
        Command::new("git")
            .args(["commit", "-m", "Automated Update"])
            .output()?;

        // Push changes
        Command::new("git").args(["push"]).output()?;

        Ok(())
    }

    async fn create_github_release(
        &self,
        full_version: &str,
        added: &[String],
        removed: &[String],
    ) -> Result<()> {
        // Read GitHub token directly from environment variable
        let github_token: String = std::env::var("GITHUB_TOKEN")
            .map_err(|_| anyhow!("GITHUB_TOKEN environment variable is required"))?;

        // Get latest commit SHA
        let output = Command::new("git").args(["rev-parse", "HEAD"]).output()?;
        let latest_sha: String = String::from_utf8_lossy(&output.stdout).trim().to_string();

        let current_time: String = Utc::now().format("%m/%d/%Y %H:%M:%S").to_string();

        let added_list: String = if added.is_empty() {
            "* \n".to_string()
        } else {
            added
                .iter()
                .map(|feature| format!("* {}\n", feature))
                .collect()
        };

        let removed_list: String = if removed.is_empty() {
            "* \n".to_string()
        } else {
            removed
                .iter()
                .map(|feature| format!("* {}\n", feature))
                .collect()
        };

        let initial_body: String = format!(
            "\n# <img width=\"35\" src=\"https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp\"> Automated update\n\n\
            ## Processed at: {} (UTC+00:00)\n\n\
            Visit the GitHub's release section for full details on how to use it:\n\
            https://github.com/SpyNetGirl/MSEdgeFeatures/releases/tag/{}\n\n\
            ### {} New features were added\n\n\
            {}\n\
            <br>\n\n\
            ### {} Features were removed\n\n\
            {}\n\
            <br>\n\n",
            current_time,
            full_version,
            added.len(),
            added_list,
            removed.len(),
            removed_list
        );

        // Create release
        let create_request: CreateReleaseRequest = CreateReleaseRequest {
            tag_name: full_version.to_string(),
            target_commitish: latest_sha,
            name: format!("Edge Canary version {}", full_version),
            body: initial_body,
            draft: false,
            prerelease: false,
        };

        // Make the API call with required User-Agent header
        let response = self
            .client
            .post("https://api.github.com/repos/SpyNetGirl/MSEdgeFeatures/releases")
            .header("Authorization", format!("token {}", github_token))
            .header("User-Agent", "edge-canary-updater/1.0")
            .json(&create_request)
            .send()
            .await?;

        // Check if the response is successful
        if !response.status().is_success() {
            let status: reqwest::StatusCode = response.status();
            let error_text: String = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow!("GitHub API error: {} - {}", status, error_text));
        }

        // Parse the response
        let response_text: String = response.text().await?;
        let release: GitHubRelease = serde_json::from_str(&response_text).map_err(|e| {
            anyhow!(
                "Failed to parse GitHub API response: {}. Response: {}",
                e,
                response_text
            )
        })?;

        // Upload asset using gh CLI
        let upload_output = Command::new("gh")
            .args([
                "release",
                "upload",
                full_version,
                "./EdgeCanaryShortcutMaker.ps1",
                "--clobber",
            ])
            .output()?;

        if !upload_output.status.success() {
            let stderr: String = String::from_utf8_lossy(&upload_output.stderr).to_string();
            return Err(anyhow!("Failed to upload asset: {}", stderr));
        }

        let asset_name: &str = "EdgeCanaryShortcutMaker.ps1";
        let asset_download_url: String = format!(
            "https://github.com/SpyNetGirl/MSEdgeFeatures/releases/download/{}/{}",
            full_version, asset_name
        );

        // Update release body with download link
        let final_body: String = format!(
            "\n# <img width=\"35\" src=\"https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp\"> Automated update\n\n\
            ## Processed at: {} (UTC+00:00)\n\n\
            ### {} New features were added\n\n\
            {}\n\
            <br>\n\n\
            ### {} Features were removed\n\n\
            {}\n\
            <br>\n\n\
            ### How to use the new features in this Edge canary update\n\n\
            1. First make sure your Edge canary is up to date\n\n\
            2. Copy and paste the code below in your PowerShell. NO admin privileges required. An Edge canary `.bat` file will be created in your Downloads folder. Double-click/tap on it to launch Edge canary with the features added in this update.\n\n\
            <br>\n\n\
            ```powershell\n\
            invoke-restMethod '{}' | Invoke-Expression\n\
            ```\n\n",
            current_time,
            added.len(),
            added_list,
            removed.len(),
            removed_list,
            asset_download_url
        );

        let update_request: UpdateReleaseRequest = UpdateReleaseRequest { body: final_body };

        // Update release
        let update_response = self
            .client
            .patch(&format!(
                "https://api.github.com/repos/SpyNetGirl/MSEdgeFeatures/releases/{}",
                release.id
            ))
            .header("Authorization", format!("token {}", github_token))
            .header("User-Agent", "edge-canary-updater/1.0")
            .header("Content-Type", "application/json")
            .json(&update_request)
            .send()
            .await?;

        if !update_response.status().is_success() {
            let status: reqwest::StatusCode = update_response.status();
            let error_text: String = update_response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow!(
                "Failed to update GitHub release: {} - {}",
                status,
                error_text
            ));
        }

        Ok(())
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // Validate that GITHUB_TOKEN environment variable exists
    if std::env::var("GITHUB_TOKEN").is_err() {
        return Err(anyhow!("GITHUB_TOKEN environment variable is required"));
    }

    let updater: EdgeUpdater = EdgeUpdater::new();
    updater.run().await
}
