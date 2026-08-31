# omarchy-plugins

Omarchy 4 shell plugins. One directory per plugin, each with a `manifest.json`
at its root, exactly as Omarchy expects — but several of them in one repo.

| plugin | id | kind | what it does |
|---|---|---|---|
| [server-mode](server-mode/) | `nixbiks.server-mode` | `bar-widget` | Toggle the always-on office box, and warn when the OLED panel is lit behind a shut lid |

## Install

```bash
./link
```

That symlinks each plugin into `~/.config/omarchy/plugins/<manifest.id>` and asks
the shell to rescan. Then enable it once:

```bash
omarchy plugin enable nixbiks.server-mode right
```

## Why a monorepo, and what it costs

`omarchy plugin add <git-url>` clones **one plugin per repo** into
`~/.config/omarchy/plugins/<manifest.id>/`, so a repo like this one cannot be
installed that way. Discovery is a different code path and more permissive —
`omarchy-plugin-catalog` runs

```
find -L "$HOME/.config/omarchy/plugins" -mindepth 2 -maxdepth 2 -type f -name manifest.json
```

`find -L` follows symlinks, so a symlink at exactly that depth is
indistinguishable from a clone. `./link` creates those, which is what lets one
repo hold many plugins.

The cost is that `omarchy plugin add` and `omarchy plugin update <id>` are not
the management path here — `add` refuses a path that already exists, and
`update` would git-pull this whole repo behind one plugin's name. Use git.

Enabling still works normally: `omarchy plugin enable/disable <id>` writes to
`bar.layout` in `~/.config/omarchy/shell.json`. **If that file is stowed from a
dotfiles repo, `enable` rewrites it in place and replaces the symlink** — edit
the repo copy and relink instead.

## Writing another one

Omarchy's own contract is the reference: `/usr/share/omarchy/shell/README.md`
for the manifest schema and `/usr/share/omarchy/shell/plugins/README.md` for the
plugin kinds. `omarchy plugin validate <folder>` checks a manifest before the
shell ever loads it, and `omarchy plugin clone <source-id> --edit` copies a
first-party plugin out of the package tree as a starting point.

Plugins run unsandboxed inside the long-lived `omarchy-shell` process. A crash
in QML takes the bar with it.
