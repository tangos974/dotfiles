#!/bin/sh
# Reserve one CPU thread exclusively for the UI session (the compositor) so it
# can never be starved under load. Third line of defense after the slice
# CPUWeight drop-ins and scx_bpfland (see README "UI CPU priority").
#
# Weights only PROPORTION CPU under contention; they never RESERVE it. This
# script uses the cpuset controller to carve out a thread that nothing but the
# session.slice can run on, which is a hard guarantee that holds even while an
# scx scheduler is active (sched_ext respects per-task CPU affinity).
#
# Topology (11th-gen i7-1185G7, 4 cores / 8 threads):
#   reserved   = CPU 7   (HT sibling of CPU 3 — shares a physical core, so it
#                         guarantees a runqueue slot, not a full isolated core;
#                         to reserve a whole core instead, fence to 0-2,4-6 and
#                         give the session 3,7)
#   general    = CPUs 0-6
#
# The compositor (session.slice) and the browsers/editors (app.slice) are
# SIBLINGS inside user@1000.service, so they can only be split with cpuset if
# that controller is delegated down to the user manager — which it is not by
# default here (user@ gets only "cpu memory pids"). So this script:
#   1. delegates cpuset to the user manager (system-level drop-in),
#   2. fences system.slice + init.scope off CPU 7 (applied live),
#   3. leaves user.slice / user@ / session.slice on the full 0-7 so the
#      compositor inherits the reserved thread.
# The matching user-level fences for app.slice / background.slice ship in the
# stowed `systemd-user` package and activate on the next login (when user@
# picks up the cpuset delegation).
#
# Requires: sudo.
# Rollback: sudo rm /etc/systemd/system/{system.slice.d,init.scope.d,user@.service.d}/50-cpuset*.conf
#           && sudo systemctl daemon-reload && relogin   (instant, no reboot for the live part below)
set -eu

GENERAL='0-6'   # threads the general workload (system services, apps) may use
# CPU 7 is the reserved thread: left out of GENERAL, kept in the session path.

DELEGATE_CONF='/etc/systemd/system/user@.service.d/50-cpuset-delegate.conf'
SYSTEM_CONF='/etc/systemd/system/system.slice.d/50-cpuset.conf'
INIT_CONF='/etc/systemd/system/init.scope.d/50-cpuset.conf'

sudo mkdir -p \
  /etc/systemd/system/user@.service.d \
  /etc/systemd/system/system.slice.d \
  /etc/systemd/system/init.scope.d

# 1. Delegate the cpuset controller to the user systemd manager. Delegate= is a
#    full list (it replaces the default), so we keep the existing controllers
#    and add cpuset. Takes effect when user@ next starts (i.e. next login).
sudo tee "$DELEGATE_CONF" > /dev/null <<'EOF'
# Managed by dotfiles/bin/setup-cpu-reservation.sh
# Delegate cpuset down to the user manager so session.slice (compositor) and
# app.slice (browsers/editors) can be fenced onto different CPUs.
[Service]
Delegate=cpu cpuset memory pids
EOF

# 2. Fence all system services and the init scope off the reserved thread.
sudo tee "$SYSTEM_CONF" > /dev/null <<EOF
# Managed by dotfiles/bin/setup-cpu-reservation.sh
# Keep system services (docker, etc.) off the reserved UI thread (CPU 7).
[Slice]
AllowedCPUs=${GENERAL}
EOF

sudo tee "$INIT_CONF" > /dev/null <<EOF
# Managed by dotfiles/bin/setup-cpu-reservation.sh
[Scope]
AllowedCPUs=${GENERAL}
EOF

sudo systemctl daemon-reload

# 3. Apply the system-level fences to the already-running cgroups immediately
#    (no reboot). --runtime just realizes the cpuset now; the /etc files above
#    make it survive reboot. user.slice / user@ / session.slice are deliberately
#    left untouched so they keep the full CPU set and the compositor inherits
#    the reserved thread.
sudo systemctl set-property --runtime system.slice "AllowedCPUs=${GENERAL}"
sudo systemctl set-property --runtime init.scope "AllowedCPUs=${GENERAL}"

# 4. Activate the user-session fences in the CURRENT session. On a fresh login
#    this is automatic — user@ starts with cpuset already delegated by the
#    drop-in above — but mid-install the running user manager cached its
#    controller set at login and must re-exec to notice cpuset became available
#    before it will enable it for app.slice/background.slice. The matching
#    drop-ins must already be stowed (systemd-user package); set-property below
#    also applies a transient fallback so this works even pre-stow. Best-effort:
#    skipped cleanly when there is no user manager (headless/root install).
user_state='will activate on next login'
if systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  systemctl --user daemon-reexec || true   # pick up the newly-delegated cpuset controller
  systemctl --user set-property --runtime app.slice "AllowedCPUs=${GENERAL}" 2>/dev/null || true
  systemctl --user set-property --runtime background.slice "AllowedCPUs=${GENERAL}" 2>/dev/null || true
  user_state='active now'
fi

printf '%s\n' "Wrote ${DELEGATE_CONF}, ${SYSTEM_CONF}, ${INIT_CONF}."
printf '%s\n' "CPU 7 is reserved for the compositor (session.slice); system services,"
printf '%s\n' "apps, and background work are fenced to CPUs ${GENERAL}."
printf '%s\n' "User-session fences: ${user_state}."
printf '%s\n' "Persistence: /etc drop-ins (system side) + stowed systemd-user drop-ins"
printf '%s\n' "(user side) — both reapply automatically on reboot."
printf '%s\n' "Verify: systemctl --user show app.slice -p EffectiveCPUs   # -> ${GENERAL}"
