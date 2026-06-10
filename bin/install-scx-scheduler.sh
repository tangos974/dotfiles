#!/usr/bin/env bash
#
# Install scx-scheds (sched_ext pluggable schedulers) and enable scx_bpfland,
# a scheduler that detects interactive tasks (compositor, input, app UI
# threads) and fast-paths them under CPU load. Second line of defense against
# desktop stutter/freezes after the systemd-user slice CPUWeight drop-ins
# (see README "UI CPU priority").
#
# The Arch scx-scheds package ships only the scheduler binaries, so this
# script also installs the upstream scx.service unit and /etc/default/scx
# (mirrors https://github.com/sched-ext/scx/blob/main/services/scx.service).
#
# Note: while an scx scheduler is active, cgroup cpu.weight is not enforced
# (bpfland uses its own per-task interactivity heuristics). The slice weights
# take over again whenever scx.service is stopped.
#
# Rollback: sudo systemctl disable --now scx.service  (instant, no reboot)

set -euo pipefail

SCHEDULER=scx_bpfland

install_pkg() {
  if pacman -Qq scx-scheds >/dev/null 2>&1; then
    echo "scx-scheds already installed — skipping pacman step."
    return 0
  fi
  sudo pacman -S --noconfirm --needed scx-scheds
}

write_default_config() {
  if grep -qE "^SCX_SCHEDULER=${SCHEDULER}\$" /etc/default/scx 2>/dev/null; then
    echo "/etc/default/scx already selects ${SCHEDULER} — skipping."
    return 0
  fi
  sudo tee /etc/default/scx >/dev/null <<EOF
# Managed by dotfiles/bin/install-scx-scheduler.sh
SCX_SCHEDULER=${SCHEDULER}
SCX_FLAGS=
EOF
}

write_service_unit() {
  if [ -f /etc/systemd/system/scx.service ]; then
    echo "/etc/systemd/system/scx.service already exists — skipping."
    return 0
  fi
  sudo tee /etc/systemd/system/scx.service >/dev/null <<'EOF'
# Managed by dotfiles/bin/install-scx-scheduler.sh
# Verbatim from https://github.com/sched-ext/scx/blob/main/services/scx.service
[Unit]
Description=Start scx_scheduler
ConditionPathIsDirectory=/sys/kernel/sched_ext
StartLimitIntervalSec=30
StartLimitBurst=2

[Service]
Type=simple
EnvironmentFile=/etc/default/scx
ExecStart=/bin/bash -c 'exec ${SCX_SCHEDULER_OVERRIDE:-$SCX_SCHEDULER} ${SCX_FLAGS_OVERRIDE:-$SCX_FLAGS} '
Restart=on-failure
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
}

main() {
  install_pkg
  write_default_config
  write_service_unit
  sudo systemctl enable --now scx.service

  echo
  echo "Done. Active sched_ext scheduler:"
  # root/ops appears a moment after the service starts; wait briefly
  for _ in 1 2 3 4 5 6; do
    [ -r /sys/kernel/sched_ext/root/ops ] && break
    sleep 0.5
  done
  cat /sys/kernel/sched_ext/root/ops 2>/dev/null \
    || echo "  (could not read /sys/kernel/sched_ext/root/ops — check: systemctl status scx.service)"
}

main "$@"
