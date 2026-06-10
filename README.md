# dotfiles

Personal dotfiles for Omarchy (Arch + Hyprland). Managed with [GNU Stow](https://www.gnu.org/software/stow/): each top-level directory is a stow package whose contents mirror their target paths.

## Bootstrap

On a fresh Omarchy install:

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./bin/master-installation.sh
```

The master script is idempotent — re-run it after pulling upstream and every step short-circuits if its work is already done.

## Layout

| Directory          | Stow target                          | What it provides                                                            |
|--------------------|--------------------------------------|-----------------------------------------------------------------------------|
| `bash/`            | `~/.bashrc`                          | Omarchy-aware bash rc                                                       |
| `fastfetch/`       | `~/.config/fastfetch/`               | fastfetch config                                                            |
| `ghostty/`         | `~/.config/ghostty/`                 | Ghostty terminal config                                                     |
| `hypr/`            | `~/.config/hypr/`                    | Hyprland config (hyprland.conf, bindings, input, monitors, hypridle, ...)   |
| `mullvad-default/` | (linked manually into Mullvad profiles) | `user.js` + `userChrome.css` for non-WebApps profiles                    |
| `mullvad-webapp/`  | (linked manually into Mullvad WebApps profile) | `user.js` + `userChrome.css` for the dedicated WebApps profile     |
| `omarchy/`         | `~/.config/omarchy/`                 | Omarchy menu extensions and theme overrides                                 |
| `omarchy-bin/`     | `~/.local/share/omarchy-overrides/bin/` | Custom omarchy commands (overrides + additions). Prepended to `$PATH` in `bash/.bashrc` so they shadow upstream. Kept out of `~/.local/share/omarchy/` to avoid breaking `omarchy-update`. |
| `systemd-user/`    | `~/.config/systemd/user/`            | Drop-ins for user systemd services (Ghostty preload, UI CPU priority)       |
| `uwsm/`            | `~/.config/uwsm/`                    | uwsm session env (default browser, editor, terminal)                        |
| `waybar/`          | `~/.config/waybar/`                  | Waybar config, style, and custom-module scripts                             |
| `bin/`             | (not stowed — invoked directly)      | All the install / setup / runtime scripts                                   |

## `bin/` script naming

| Prefix    | What it does                                                                |
|-----------|-----------------------------------------------------------------------------|
| `install-`| Installs a package (yay/pacman/AUR). Short-circuits if already installed.   |
| `stow-`   | Stows a dotfiles package (no package install).                              |
| `setup-`  | Configures something already installed: writes drop-ins, links profiles, mutates live state. |

The master script invokes them in four phases (see `bin/master-installation.sh`):

1. **Prerequisites** — install GNU Stow.
2. **Packages and base config stows** — install tools (Mullvad, terminals, CLI tools) and stow their configs.
3. **Per-feature setup** — keyboard layouts, ghostty preload, lid/sleep drop-ins, preload daemon, Hyprland exec-once helpers.
4. **Webapps + Mullvad profile chrome**, then **optional cleanup**.

## Common per-feature scripts

- `setup-keyboard-layouts.sh` — wires the Waybar UK/US/FR indicator + gum TUI manager.
- `setup-ghostty-preload.sh` — keeps Ghostty alive after the last window closes (user systemd service override).
- `setup-systemd-lid-sleep.sh` — installs `/etc/systemd/{logind,sleep}.conf.d/` drop-ins for suspend-then-hibernate.
- `setup-limine-quiet-boot.sh` — optional: edits `/boot/limine.conf` for a quieter boot screen (run manually).
- `setup-mullvad-profiles.sh` / `setup-mullvad-policies.sh` — install Mullvad Browser configuration (see [Mullvad Browser profiles](#mullvad-browser-profiles)).

## Hyprland helpers

Two scripts run via `exec-once` from `hypr/.config/hypr/hyprland.conf` and live at `~/.local/bin/` (symlinked into place by `master-installation.sh`):

- `adapt-workspaces.sh` — generates `~/.config/hypr/workspace-layout.generated.conf` and `~/.config/waybar/workspaces.generated.jsonc` based on the current monitor layout, then reloads Hyprland and Waybar. Distributes the 10 workspaces across detected monitors with the remainder weighted to the rightmost monitor.
- `watch-monitor-events.sh` — listens to the Hyprland event socket (`activelayout`, `monitoradded`, `monitorremoved`) and reruns `adapt-workspaces.sh` whenever monitors change.

## UI CPU priority

Under CPU load (builds, browser tabs, video encode) the default scheduler treats Hyprland like any other process, so the compositor misses frame deadlines and every monitor stutters — which wrecks video calls. uwsm already puts the compositor (plus pipewire/wireplumber) in `session.slice` and regular apps in `app.slice/app-graphical.slice`; the `systemd-user` package adds slice drop-ins that turn that placement into actual priority:

- `session.slice.d/50-cpuweight.conf` — `CPUWeight=500` (5x the default 100 of `app.slice`)
- `background.slice.d/50-cpuweight.conf` — `CPUWeight=25` (use `uwsm app -s b -- <cmd>` to launch something deprioritized)

Weights are relative between sibling slices and only bite under contention; an idle machine behaves identically. Applied via the normal `stow_pkg systemd-user` + `systemctl --user daemon-reload` in the master script.

Slice weights only protect the compositor from *sibling user slices*: they do nothing against `system.slice` load (docker containers), and a starved app still freezes its own window even when Hyprland composites smoothly. The second layer is `install-scx-scheduler.sh`, which enables `scx_bpfland` (sched_ext pluggable scheduler, `scx.service`): it detects interactive tasks by wakeup pattern — compositor, input handlers, app UI threads alike — and fast-paths them under load. While scx is active the cgroup weights above are not enforced (bpfland uses its own heuristics); they take over again on `sudo systemctl disable --now scx.service`, which is also the instant rollback.

## Mullvad Browser profiles

Three profiles are defined by the dotfiles: **Perso** (default), **Easier**, **WebApps**. The full setup lives across five packages:

- `mullvad-profiles/profiles.ini` — names, fixed relative `Path=Perso|Easier|WebApps`, and `Default=1` on Perso. Installed as a **copy** (not stowed): the browser rewrites `profiles.ini` on first launch to add a machine-specific `[InstallXXXX]` hash, which would churn a stow symlink.
- `mullvad-perso/` / `mullvad-easier/` / `mullvad-webapp/` — each holds the profile's `user.js` and `userChrome.css`. `setup-mullvad-profiles.sh` symlinks them into the matching profile dir under `~/.mullvad/mullvadbrowser/`.
- `mullvad-policies/policies.json` — extension/policy settings shared by all profiles, copied (sudo) into `/opt/mullvad-browser/distribution/` by `setup-mullvad-policies.sh`.

`setup-mullvad-profiles.sh` aborts if the browser is running, then renames any pre-existing random-prefix profile dirs (`xxxxxxxx.Easier`, `*.default-release`, …) to the deterministic names — preserving browsing data — before linking the templates.

## Stow conflict handling

`bin/dotfiles-stow.sh` exposes `stow_pkg <pkg>`, which auto-backs-up any conflicting non-symlink files into `~/.local/state/dotfiles-stow-backups/<pkg>/<file>` before stowing. There is also a `backup_if_needed <path>` helper for ad-hoc symlinks outside any stow package (used by the Mullvad profile-chrome setup scripts).

## Conventions

- Tracked dotfiles are the source of truth — install scripts do **not** mutate any tracked file. Adding a new keybinding or env var means committing it to `hypr/.config/hypr/bindings.conf` (or wherever) directly.
- The `*.before-stow` and older `*.pre-stow` files alongside live configs are backups created during the original migration; safe to delete once you trust the stowed versions.
