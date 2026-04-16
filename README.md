# FlClash (Fork)

This is a personal fork of [chen08209/FlClash](https://github.com/chen08209/FlClash), a multi-platform proxy client based on ClashMeta.

## Added Features

### Override Script Sync

- **Remote URL binding per script** — each script can be associated with a remote URL (e.g. GitHub Gist). The URL is stored persistently so you never have to re-enter it.
- **Import from URL** — in the script editor, tap the three-dot menu → *External Fetch* → *Import from URL*. The dialog remembers the last URL used for that script.
- **Sync button in script list** — a sync button is always visible in the top-right area of the script list:
  - When no script is selected: syncs all scripts that have a remote URL.
  - When a script is selected: syncs only that script.
- **Last-sync time display** — each script item shows how long ago it was last synced (e.g. *Just now*, *5 minutes ago*, *2 days ago*). Scripts without a remote URL show *Local*.
- **Auto-sync on profile update** — when a profile is refreshed, any linked override script that has a remote URL is automatically synced as well.
- **Sync time in overwrite selector** — the script selector inside the profile override settings also shows the last-sync time for each script entry.

## Release

Android APKs are built and published automatically when a `v*` tag is pushed to this repository.

> Upstream project: <https://github.com/chen08209/FlClash>
