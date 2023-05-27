# What is this repository ?

This is a fully automated repository, tasked with identifying the features added or removed in each Edge canary channel update.

These features are [Controlled Feature Rollouts](https://techcommunity.microsoft.com/t5/articles/controlled-feature-roll-outs-in-microsoft-edge/m-p/763678).

By identifying the changes, you can enable and experience specific new features in Edge canary before anyone else, or before the feature is even officially enabled for anyone.

The GitHub action runs every 12 hours and only during weekdays since Edge Canary channel doesn't get updates during weekends.

## How to use ?

Run this in PowerShell (No admin privileges required) without downloading

```powershell
Invoke-RestMethod 'https://raw.githubusercontent.com/HotCakeX/MSEdgeFeatures/main/Shortcut.ps1' | Invoke-Expression
```

Or [download](https://github.com/HotCakeX/MSEdgeFeatures/blob/main/Shortcut.ps1) it on your system and then run.

It will create an Edge canary shortcut in your Downloads folder. This shortcut includes all of the new features that were added in the latest Edge canary update. You can verify it by right-clicking on it and viewing the Target of the shortcut.

Once you launch Edge canary using the shortcut, you can check out more info about what features are enabled in Edge canary by visiting this page: `edge://version/` and looking at the **Command-line** section.
