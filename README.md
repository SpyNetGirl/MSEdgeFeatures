# [What is This Repository ?](#what-is-this-repository--) <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/angry%20cat%20on%20the%20table.gif">

This is a fully automated repository, tasked with identifying the features added or removed in each [Edge canary channel update.](https://www.microsoftedgeinsider.com/en-us/download/)

These features are [Controlled Feature Rollouts](https://techcommunity.microsoft.com/t5/articles/controlled-feature-roll-outs-in-microsoft-edge/m-p/763678).

By identifying the changes, you can enable and experience specific new features in Edge canary before anyone else, or before the feature is even officially enabled for anyone.

The [GitHub action](https://github.com/HotCakeX/MSEdgeFeatures/blob/main/.github/workflows/Update.yml) runs every 8 hours.

[![Update](https://github.com/HotCakeX/MSEdgeFeatures/actions/workflows/Update.yml/badge.svg)](https://github.com/HotCakeX/MSEdgeFeatures/actions/workflows/Update.yml)

[Releases](https://github.com/HotCakeX/MSEdgeFeatures/releases) are published for each update automatically, giving an overview of what features were added and removed in each version.

Make sure you select the ***Watch*** option at the top of this page to receive notifications on your GitHub and Email whenever a new version of Edge Canary is released.

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## [Last Run Details](#last-run-details-) <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/i%20just%20dont%20know.gif">
<!-- Edge-Canary-Version:START -->
### <a href="https://github.com/HotCakeX/MSEdgeFeatures"><img width="35" src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp"></a> Latest Edge Canary version: 128.0.2706.0

### Last processed at: 07/11/2024 16:06:51 (UTC+00:00)

<details>
<summary>0 new features were added in the latest Edge Canary update</summary>

<br>

* 

</details>
<!-- Edge-Canary-Version:END -->

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## [How to Use ?](#how-to-use--) <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/Nyan%20cat.gif">

1. Install PowerShell Core latest version
     * Get it from the [official GitHub repository](https://github.com/PowerShell/PowerShell/releases)
     * Or Install it from [Microsoft Store](https://apps.microsoft.com/store/detail/powershell/9MZ1SNWT0N5D)

2. Navigate to the [Releases section](https://github.com/HotCakeX/MSEdgeFeatures/releases) of this GitHub repository, find the latest update which is at the top, or any other previous update that you are looking for, copy the PowerShell code in that release, paste it in your PowerShell Core (no admin required), it will create the Edge canary batch file (`.bat` file) for you in the Downloads folder of your computer.

You can start Edge canary with that `.bat` file and try out the new features added in that specific Edge canary update.

You can verify the `.bat` file by opening it in a text editor such as VS Code.

Once you launch Edge canary using the `.bat` file, you can check out more info about what features are enabled in Edge canary by visiting this page: `edge://version/` and looking at the **Command-line** section.

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## [Feel Free to Share Your Findings !](#feel-free-to-share-your-findings--) <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/hand%20love%20gesture.gif">

I might sometimes post notable new features I come across [in the Discussions section](https://github.com/HotCakeX/MSEdgeFeatures/discussions), you can do the same and let us know what you find!

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## [Things to Note](#things-to-note-) <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/Windows%20Hello%20Small.gif">

* Sometimes feature flags with similar names should be used together in order to activate a certain feature, using them individually might not activate anything.

<br>
