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
| `bin/`             | (not stowed — invoked directly)      | All the install / setup / runtime scripts                                   || `opencode/`        | `~/.config/opencode/`                | OpenCode agent config (see [OpenCode](#opencode)): default model + homelab llama-swap provider, custom agents, SearXNG MCP server, and agent prompts. Runtime state (`opencode.db`, `node_modules/`, …) is gitignored. |
| `mise/`            | `~/.config/mise/`                    | [mise](https://mise.jdx.dev) tool pins: `node` on the LTS line; `go`/`python`/`uv`/`terraform`/`ansible-core` tracking `latest`. Shell activation lives in `bash/.bashrc`; `install-mise.sh` installs mise + the tools. node from here provides the `npx` the Playwright MCP needs. |

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
- `install-speech-dispatcher.sh` — installs speech-dispatcher wired to homelab TTS (see [Text-to-speech (FastKoko)](#text-to-speech-fastkoko)).

## Hyprland helpers

Two scripts run via `exec-once` from `hypr/.config/hypr/hyprland.conf` and live at `~/.local/bin/` (symlinked into place by `master-installation.sh`):

- `adapt-workspaces.sh` — generates `~/.config/hypr/workspace-layout.generated.conf` and `~/.config/waybar/workspaces.generated.jsonc` based on the current monitor layout, then reloads Hyprland and Waybar. Distributes the 10 workspaces across detected monitors with the remainder weighted to the rightmost monitor.
- `watch-monitor-events.sh` — listens to the Hyprland event socket (`activelayout`, `monitoradded`, `monitorremoved`) and reruns `adapt-workspaces.sh` whenever monitors change.

## Always-on mode

The eye icon in Waybar switches the machine between two power behaviours. A dimmed closed eye is normal omarchy idling; an open, highlighted eye is always-on, where nothing is allowed to interrupt a long-running task. Normal sleep is always the default — the state is deliberately not persisted, so a reboot or re-login lands back in it.

Always-on is a single `systemd-inhibit` block lock, held for as long as `systemd-user/.config/systemd/user/always-on.service` runs. It names three inhibitor types because three independent subsystems can each stop this machine:

- `idle` — hypridle pauses every listener in `hypr/.config/hypr/hypridle.conf` (screensaver at 5 min, lock, display off, suspend-then-hibernate at 10 min). It honours the lock because `general:ignore_systemd_inhibit` defaults to `false`.
- `sleep` — logind refuses suspend and hibernate, including a manual request from the power menu.
- `handle-lid-switch` — logind ignores the lid, overriding the `HandleLidSwitch=suspend-then-hibernate` drop-in from `setup-systemd-lid-sleep.sh`. This is a *low level* lock, which logind honours unconditionally; `LidSwitchIgnoreInhibited` defaults to `yes` and would otherwise make the lid discard plain `sleep`/`idle` locks.

The unit has no `[Install]` section, so it cannot be enabled at boot. Stopping it kills the one `sleep infinity` child and releases the lock immediately — there is no saved state to restore, and `systemd-inhibit --list` shows the lock while it is held. The Waybar module is the usual oneshot poll (`always-on-status.sh`, `interval: 10`, `signal: 12`); `always-on-toggle.sh` starts or stops the unit, notifies, and signals the bar to redraw at once.

## UI CPU priority

Under CPU load (builds, browser tabs, video encode) the default scheduler treats Hyprland like any other process, so the compositor misses frame deadlines and every monitor stutters — which wrecks video calls. uwsm already puts the compositor (plus pipewire/wireplumber) in `session.slice` and regular apps in `app.slice/app-graphical.slice`; the `systemd-user` package adds slice drop-ins that turn that placement into actual priority:

- `session.slice.d/50-cpuweight.conf` — `CPUWeight=500` (5x the default 100 of `app.slice`)
- `background.slice.d/50-cpuweight.conf` — `CPUWeight=25` (use `uwsm app -s b -- <cmd>` to launch something deprioritized)

Weights are relative between sibling slices and only bite under contention; an idle machine behaves identically. Applied via the normal `stow_pkg systemd-user` + `systemctl --user daemon-reload` in the master script.

Slice weights only protect the compositor from *sibling user slices*: they do nothing against `system.slice` load (docker containers), and a starved app still freezes its own window even when Hyprland composites smoothly. The second layer is `install-scx-scheduler.sh`, which enables `scx_bpfland` (sched_ext pluggable scheduler, `scx.service`): it detects interactive tasks by wakeup pattern — compositor, input handlers, app UI threads alike — and fast-paths them under load. While scx is active the cgroup weights above are not enforced (bpfland uses its own heuristics); they take over again on `sudo systemctl disable --now scx.service`, which is also the instant rollback.

Weights and scx both *proportion* CPU — neither *reserves* it, so neither is an absolute guarantee. The third layer, `setup-cpu-reservation.sh`, gives one. It uses the `cpuset` controller to fence every general workload off **CPU 7** (`AllowedCPUs=0-6` on `system.slice`, `init.scope`, and — in the user manager — `app.slice`/`background.slice`) while leaving `session.slice` on the full `0-7`. The compositor therefore always has CPU 7 available with nothing else queued on it, a hard floor that holds even under scx (sched_ext honours CPU affinity). Because the compositor and the browsers are siblings inside `user@1000.service`, splitting them requires the `cpuset` controller to be delegated to the user manager (it isn't by default — only `cpu memory pids`); the script adds that delegation system-side. A fresh login picks it up automatically; mid-install the script re-execs the user manager (`systemctl --user daemon-reexec`) so the `app.slice`/`background.slice` fences bind live without a logout. CPU 7 is the HT sibling of CPU 3, so this guarantees a runqueue slot rather than a fully isolated core — enough to kill frame-stutter; reserve `3,7` as a pair if one thread proves tight. Rollback: remove the `50-cpuset*.conf` drop-ins under `/etc/systemd/system/{system.slice.d,init.scope.d,user@.service.d}/`, `daemon-reload`, and relogin.

## Mullvad Browser profiles

Three profiles are defined by the dotfiles: **Perso** (default), **Easier**, **WebApps**. The full setup lives across five packages:

- `mullvad-profiles/profiles.ini` — names, fixed relative `Path=Perso|Easier|WebApps`, and `Default=1` on Perso. Installed as a **copy** (not stowed): the browser rewrites `profiles.ini` on first launch to add a machine-specific `[InstallXXXX]` hash, which would churn a stow symlink.
- `mullvad-perso/` / `mullvad-easier/` / `mullvad-webapp/` — each holds the profile's `user.js` and `userChrome.css`. `setup-mullvad-profiles.sh` symlinks them into the matching profile dir under `~/.mullvad/mullvadbrowser/`.
- `mullvad-policies/policies.json` — extension/policy settings shared by all profiles, copied (sudo) into `/opt/mullvad-browser/distribution/` by `setup-mullvad-policies.sh`.

`setup-mullvad-profiles.sh` aborts if the browser is running, then renames any pre-existing random-prefix profile dirs (`xxxxxxxx.Easier`, `*.default-release`, …) to the deterministic names — preserving browsing data — before linking the templates.

## Runtimes (mise)

Language runtimes and CLI tools are pinned with [mise](https://mise.jdx.dev). The pins live in the `mise/` package (`~/.config/mise/config.toml`): `node` tracks the LTS line, while `go`, `python`, `uv`, `terraform`, and `ansible-core` (pipx backend) track `latest`. `latest` trades exact reproducibility for freshness — a fresh clone installs whatever is newest then, and `mise upgrade` bumps in place. `lts` is a node-only keyword; the others have no LTS line, so `latest` (or a fixed version) is the equivalent. Shell activation is already wired in `bash/.bashrc`. `install-mise.sh` installs mise (pacman, else yay, else `mise.run`), stows the pins, and runs `mise install`; it is a phase-0 prerequisite because later steps depend on it — notably the Playwright MCP, whose `npx` comes from this node. `kubectl`/`kubectx`/`k9s` are installed separately via `install-kubernetes-tools.sh` (pacman), not mise.

## OpenCode

[OpenCode](https://opencode.ai) is the terminal AI agent configured for the homelab; the `opencode/` package stows into `~/.config/opencode/`. Only hand-authored config is tracked — the 1 GB+ `opencode.db`, `node_modules/`, logs and snapshots live under `~/.local/share/opencode/` and stay machine-local. `setup-opencode.sh` stows the package and wires the skill link; the `opencode` binary itself is installed separately.

- **Provider + model** — a `homelab` provider in `opencode.json` points at the llama-swap endpoint on the LAN and defaults to a local Qwen3 model, so no cloud key is needed (the `apiKey` there is a local llama-swap placeholder, not a secret).
- **Agents** — three custom agents (`explore`, `browser`, `research`), each with a system prompt under `prompts/` and scoped tool permissions.
- **Web search** — `mcp/searxng_mcp.py` is a zero-dependency MCP stdio server fronting the homelab SearXNG; it backs the `websearch` tool the agents use instead of guessing URLs.
- **Browser (Playwright)** — the `browser` agent drives headless Chromium via the `playwright` MCP (`npx @playwright/mcp`, version-pinned). Only the registration is in `opencode.json`; node (provided by mise) and the Chromium binaries in `~/.cache/ms-playwright` are large/mutable and not committed. `install-playwright.sh` (invoked by `setup-opencode.sh`) fetches them — the principle: track the install step, not the artifact.
- **Stealth browser** — runs as a **remote MCP served from the homelab** (Camoufox in a container), not on this desktop. It's registered in `opencode.json` as a `type: remote` server and allowed on the `browser` agent, but `enabled: false` with a placeholder URL until the homelab service exists — see `~/Homelab/stealth_browser_todo.md`. It replaces the old local Camoufox fetcher for bot-walled pages (Reddit / Cloudflare) that the headless Playwright `browser` agent gets blocked on.

## Text-to-speech (FastKoko)

System-wide TTS (`spd-say`, browser readers, Orca, anything speaking through speech-dispatcher) is served by FastKoko — the Kokoro-FastAPI container on the homelab inference box (`http://inference.home:8880`) — instead of a local synthesizer. The integration is speech-dispatcher's `sd_generic` module: no code, just config. The `speech-dispatcher/` package stows a thin `speechd.conf` (routes everything to the `kokoro` module), `modules/kokoro.conf` (voice map + rate scaling), and `~/.local/bin/kokoro-speak`, which builds the JSON request with `jq` (so quotes/newlines in the text can't break it), POSTs to the OpenAI-compatible `/v1/audio/speech` endpoint, and pipes the mp3 into `mpv`. speechd's −100…+100 rate maps onto the API's `speed` parameter via `GenericRateAdd`/`GenericRateMultiply` in `kokoro.conf`. Voices are per-language (`en` → `af_heart`, `fr` → `ff_siwis`, …): `spd-say -l fr "bonjour"` speaks French; `kokoro-speak` also works standalone on a pipe. `install-speech-dispatcher.sh` installs the packages and stows the config; if the inference box is down, speech fails silently (3 s connect timeout) rather than hanging.

The everyday entry point is a keybinding, not the CLI: **SUPER+ALT+R** reads the highlighted text in any app (`speak-selection` takes the primary selection, falls back to the clipboard, and picks the French or English voice by comparing stopword counts); **SUPER+ALT+SHIFT+R** stops. This replaces in-browser read-aloud entirely — Mullvad's resist-fingerprinting disables the Web Speech API, and Chromium's speech-dispatcher backend never shipped in a usable state — which is why the Read Aloud extension was dropped from `mullvad-policies/policies.json`.

The Waybar `custom/tts` module (usual oneshot poll: `tts-ctl status`, `interval: 30`, `signal: 15`) shows a speech icon: dimmed when read-aloud is off, voice name shown in blue when a voice is forced. Left click toggles on/off, middle click toggles forcing the picked voice over language auto-detect, right click opens a walker dmenu voice picker (fed from `spd-say -L`, so it always matches `kokoro.conf`, which lists only the French and American-English voices — the server has more). State is marker files under `~/.local/state/kokoro-tts/`, shared between `tts-ctl` and `speak-selection`; when unforced, the picked voice is used whenever its language matches the detected one, otherwise the language default applies.

## Stow conflict handling

`bin/dotfiles-stow.sh` exposes `stow_pkg <pkg>`, which auto-backs-up any conflicting non-symlink files into `~/.local/state/dotfiles-stow-backups/<pkg>/<file>` before stowing. There is also a `backup_if_needed <path>` helper for ad-hoc symlinks outside any stow package (used by the Mullvad profile-chrome setup scripts).

## Conventions

- Tracked dotfiles are the source of truth — install scripts do **not** mutate any tracked file. Adding a new keybinding or env var means committing it to `hypr/.config/hypr/bindings.conf` (or wherever) directly.
- The `*.before-stow` and older `*.pre-stow` files alongside live configs are backups created during the original migration; safe to delete once you trust the stowed versions.
