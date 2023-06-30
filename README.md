# What is this repository ? <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/angry%20cat%20on%20the%20table.gif">

This is a fully automated repository, tasked with identifying the features added or removed in each [Edge canary channel update.](https://www.microsoftedgeinsider.com/en-us/download/)

These features are [Controlled Feature Rollouts](https://techcommunity.microsoft.com/t5/articles/controlled-feature-roll-outs-in-microsoft-edge/m-p/763678).

By identifying the changes, you can enable and experience specific new features in Edge canary before anyone else, or before the feature is even officially enabled for anyone.

The [GitHub action](https://github.com/HotCakeX/MSEdgeFeatures/blob/main/.github/workflows/Update.yml) runs every 12 hours.

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## Last run details <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/i%20just%20dont%20know.gif">
<!-- Edge-Canary-Version:START -->
### <a href="https://github.com/HotCakeX/MSEdgeFeatures"><img width="35" src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/WebP/Edge%20Canary.webp"></a> Latest Edge Canary version: 117.0.1951.0

### Last processed at: 06/30/2023 18:26:52 (UTC+00:00)

<details>
<summary>8 new features were added in the latest Edge Canary update</summary>

<br>

* msEdgeCopilotChataDataInFeedback
 * msEdgeDetectInjectedKeyEvent
 * msEdgeDiscoverBizChatClientUI
 * msEdgeRewardsFeedbackV2
 * msEdgeVerticalTabsPromoNoFlyoutWhenOmniboxFocused
 * msManagedSiteIndicatorDLPPolicyView
 * msUndersideChatSelectedTextListenerDisabled
 * msUndersideFrontLoadServerExp

</details>
<!-- Edge-Canary-Version:END -->

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## How to use ? <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/Nyan%20cat.gif">

Run this in PowerShell without downloading *(No admin privileges required)*

```powershell
Invoke-RestMethod 'https://raw.githubusercontent.com/HotCakeX/MSEdgeFeatures/main/Shortcut.ps1' | Invoke-Expression
```

Or [download](https://github.com/HotCakeX/MSEdgeFeatures/blob/main/Shortcut.ps1) it on your system and then run.

It will create an Edge canary shortcut in your Downloads folder. This shortcut includes all the new features that were added in the latest Edge canary update. You can verify it by right-clicking on it and viewing the Target of the shortcut.

Once you launch Edge canary using the shortcut, you can check out more info about what features are enabled in Edge canary by visiting this page: `edge://version/` and looking at the **Command-line** section.

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## Feel free to share your findings ! <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/hand%20love%20gesture.gif">

I might sometimes post notable new features I come across [in the Discussions section](https://github.com/HotCakeX/MSEdgeFeatures/discussions), you can do the same and let us know what you find!

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

## Things to note <img src="https://raw.githubusercontent.com/HotCakeX/Harden-Windows-Security/main/images/Gifs/Windows%20Hello%20Small.gif">

* The max number of characters the feature flags can consume is roughly `1000`, if they exceed that number, they will be ignored.

* Sometimes feature flags with similar names should be used together in order to activate a certain feature, using them individually might not activate anything.

<br>
