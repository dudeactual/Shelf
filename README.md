# Shelf

Shelf is a native macOS holding space for links, files, and quick notes.

Drop something into Shelf, and it is copied into `~/Documents/Shelf`. Links and text are saved as normal `.txt` files, so the data stays simple and portable.

## Download

Shelf is intended to be distributed for free through GitHub Releases.

Latest release URL:

```text
https://github.com/dudeactual/Shelf/releases/latest
```

## Important macOS warning

This free release setup uses ad-hoc signing. It does **not** Apple-notarize the app.

That means some users may see:

> “Shelf” cannot be opened because the developer cannot be verified.

They can still open it by right-clicking `Shelf.app`, choosing **Open**, then choosing **Open** again.

To remove that warning for normal public distribution, Shelf needs Apple Developer ID signing and Apple notarization.

## Build locally

```sh
./script/build_and_run.sh
```

Shelf requires macOS 14 or newer.

## Create a downloadable release locally

```sh
VERSION=1.0.0 ./script/package_release.sh
```

This creates:

- `releases/Shelf-1.0.0.zip`
- `releases/Shelf-1.0.0.dmg`

The packaged `.app` is staged in `/tmp`, not inside the workspace, so Codex does not show duplicate app buttons.

## GitHub release flow

After this folder is pushed to GitHub, publish a new free download by creating a version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will build Shelf and attach the `.zip` and `.dmg` to a GitHub Release.

## Updates

Simple update path:

1. Make changes to Shelf.
2. Bump the version tag, for example `v1.0.1`.
3. Push the tag.
4. Users download the newest build from GitHub Releases.

Shelf includes a **Check for Updates** button that opens the latest GitHub Release page.

Better update path later:

- Add [Sparkle](https://sparkle-project.org/) so Shelf can show **Check for Updates** and eventually auto-update itself.
- Sparkle can use the GitHub Releases feed as the source of updates.

## Where items are saved

Everything lives in `~/Documents/Shelf`:

- Dropped files are copied into the folder.
- Web links are saved as `.txt` files containing the URL.
- Dropped text is saved as `.txt` notes.
- `.shelf-index.json` stores pinning and display metadata.
