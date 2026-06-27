# Security Policy

Thanks for helping keep Shelf safe.

## Supported versions

Security fixes are handled for the latest public release of Shelf.

| Version | Supported |
| --- | --- |
| Latest release | Yes |
| Older releases | Best effort |

Download the newest version here:

https://github.com/dudeactual/Shelf/releases/latest

## Reporting a vulnerability

Please do not open a public GitHub issue for security problems.

Instead, report security concerns through one of these private channels:

- Join the Shelf Discord and contact the maintainer: https://discord.gg/kpaZC6YPWZ
- If GitHub private vulnerability reporting is enabled for this repo, use GitHub’s **Report a vulnerability** button.

Please include:

- What happened
- Steps to reproduce it
- Your macOS version
- Your Shelf version
- Any screenshots or logs that help explain the issue

## What Shelf stores

Shelf stores user data locally in:

```text
~/Documents/Shelf
```

Shelf saves links as `.txt` files, notes as `.txt` files, and copied files as regular files. Shelf does not intentionally upload saved items to a server.

## Update safety

Shelf currently sends users to GitHub Releases for updates. Users should download updates only from:

https://github.com/dudeactual/Shelf/releases/latest

## Scope

Security reports are most useful when they involve:

- Unsafe file handling
- Unexpected network behavior
- Data loss
- Permission issues
- App update/download risks
- Bugs that could expose saved Shelf data
