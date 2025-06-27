#!/usr/bin/env bash
set -euo pipefail

# Install and enable unattended-upgrades on Debian 12
#
# The behaviour can be tuned through the following environment variables:
#   AUTO_REBOOT="1"   - automatically reboot if required after upgrades.
#                       Set to "0" to disable automatic rebooting.
#   AUTO_REBOOT_TIME   - time of day for the reboot (default "02:00").
#
# These allow you to balance security (installing updates and rebooting as
# soon as possible) against uptime (avoiding unexpected reboots).
#
# Example:
#   AUTO_REBOOT=0 ./setup_unattended_upgrades.sh

AUTO_REBOOT="${AUTO_REBOOT:-1}"
AUTO_REBOOT_TIME="${AUTO_REBOOT_TIME:-02:00}"
sudo apt-get update
sudo apt-get install -y unattended-upgrades apt-listchanges

# Configure unattended-upgrades non-interactively
sudo dpkg-reconfigure --frontend=noninteractive unattended-upgrades

# Ensure the timer is enabled and started
sudo systemctl enable --now unattended-upgrades.service >/dev/null 2>&1 || true

# Basic APT periodic configuration
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'CFG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CFG

# Configure reboot behaviour
sudo tee /etc/apt/apt.conf.d/51auto-reboot >/dev/null <<CFG
Unattended-Upgrade::Automatic-Reboot "${AUTO_REBOOT}";
Unattended-Upgrade::Automatic-Reboot-Time "${AUTO_REBOOT_TIME}";
CFG

echo "Unattended-upgrades installed and configured."

