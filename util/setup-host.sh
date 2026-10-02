# THIS IS FOR SETTING UP HOST SYSTEM DEPS THAT ARE REQUIRED TO SUPPORT ROOTLESS DinD

# Enable cgroup delegation for non-root users on host
#!/usr/bin/env bash
set -euo pipefail

TARGET_UID="${SUDO_UID:-$(id -u)}"
SERVICE_NAME="user@${TARGET_UID}.service"

# Check if systemd delegation is already enabled
DELEGATE_STATUS=$(systemctl show "${SERVICE_NAME}" -p Delegate 2>/dev/null | cut -d= -f2 || echo "no")

if [ "${DELEGATE_STATUS}" != "no" ] && [ -n "${DELEGATE_STATUS}" ]; then
  echo "✓ Cgroup delegation is already enabled (${DELEGATE_STATUS}). No changes needed."
else
  echo "✗ Delegation not found. Applying systemd configuration..."
  
  sudo mkdir -p /etc/systemd/system/user@.service.d/
  cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF

  sudo systemctl daemon-reload
  echo "✓ Done! Restarting user manager so the changes to apply."
  sudo systemctl restart user@$(id -u).service
fi