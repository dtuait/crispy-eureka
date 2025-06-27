#!/usr/bin/env bash
set -euo pipefail

# Install and enable unattended-upgrades on Debian 12
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

echo "Unattended-upgrades installed and configured."
