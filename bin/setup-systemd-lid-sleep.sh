#!/bin/sh
# Install systemd logind + sleep drop-ins for lid and suspend-then-hibernate.
# Requires: sudo. Hibernate needs swap (file or partition) configured separately.
set -eu

LID_CONF='/etc/systemd/logind.conf.d/70-lid.conf'
SLEEP_CONF='/etc/systemd/sleep.conf.d/70-sleep.conf'

sudo mkdir -p /etc/systemd/logind.conf.d /etc/systemd/sleep.conf.d

sudo tee "$LID_CONF" > /dev/null <<'EOF'
# /etc/systemd/logind.conf.d/70-lid.conf
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF

sudo tee "$SLEEP_CONF" > /dev/null <<'EOF'
# /etc/systemd/sleep.conf.d/70-sleep.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
AllowHybridSleep=no
HibernateDelaySec=30min
EOF

printf '%s\n' "Wrote ${LID_CONF} and ${SLEEP_CONF}."
printf '%s\n' "Changes take effect on next login or reboot (restarting systemd-logind kills sessions)."
printf '%s\n' "If hibernate fails, ensure swap is large enough and resume is set up (see Arch Wiki: Power management/Suspend and hibernate)."
