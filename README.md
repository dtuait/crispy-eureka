# crispy-eureka

This repository provides two scripts:

1. **setup_unattended_upgrades.sh** – installs and enables automatic security
   updates on Debian or Ubuntu.
2. **pull_vaultwarden_backups.py** – optionally sends a short status email
   about updates and system resources.

## Setting up unattended upgrades

Run the following with root privileges:

```bash
sudo ./setup_unattended_upgrades.sh
```

The script is developed on Debian 12 but is fully compatible with
Debian 11 and Ubuntu releases.

The script installs the required packages, enables the systemd service and
creates a basic `/etc/apt/apt.conf.d/20auto-upgrades` configuration so that
security updates are installed automatically.

### Balancing security and uptime

`setup_unattended_upgrades.sh` reboots the host whenever a package requires it.
This keeps the system as secure as possible but may reduce uptime. The
behaviour can be tuned using environment variables when running the script:

```bash
# disable reboots after upgrades
AUTO_REBOOT=0 ./setup_unattended_upgrades.sh

# or change the reboot time (defaults to 02:00)
AUTO_REBOOT_TIME=04:00 ./setup_unattended_upgrades.sh
```

Set `AUTO_REBOOT` to `1` (the default) to reboot automatically. Adjust
`AUTO_REBOOT_TIME` to a suitable maintenance window so updates apply promptly
without unexpected downtime.

### Example configurations

To run upgrades at a specific time you may edit the `unattended-upgrades.timer`
unit. For instance, setting `OnCalendar=*-*-* 02:00` will start applying
updates at 02:00. Combine this with `AUTO_REBOOT_TIME` to control when the
system reboots if required.

#### Optimized for security

Apply updates early and reboot soon after:

```bash
AUTO_REBOOT=1 AUTO_REBOOT_TIME=02:00 ./setup_unattended_upgrades.sh
```

#### Optimized for uptime

Delay the reboot to a quieter period, or disable it entirely:

```bash
# run updates at 02:00, reboot later if needed
AUTO_REBOOT=1 AUTO_REBOOT_TIME=04:00 ./setup_unattended_upgrades.sh

# no automatic reboot
AUTO_REBOOT=0 ./setup_unattended_upgrades.sh
```

## Notification script (optional)

This Python script emails whether security updates are pending and provides
basic system statistics.  It requires Python 3 and a small virtual
environment.

### Getting started with Python

Create the environment and install the dependencies so that modules such as
`psutil` are available:

```bash
sudo apt-get install python3-venv  # if not already installed
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Once activated, the `venv` directory contains the Python interpreter and
packages needed to run `pull_vaultwarden_backups.py`.

### Configuring mail

Copy the provided `.env.local.example` to `.env.local` next to the script and
adjust the values to match your environment. A quick way to create the file is
to run `cp .env.local.example .env.local`:

```
FROM_ADDR=you@example.com
TO_ADDR=you@example.com
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USER=your_user
SMTP_PASS=your_pass
MAIL_SUBJECT=Vaultwarden Backup Summary
```

Run the script manually to test:

```bash
./pull_vaultwarden_backups.py
```

### Cron example

Add a cron entry to run the script daily at 03:00:

```
0 3 * * * /path/to/venv/bin/python /path/to/pull_vaultwarden_backups.py
```

The script will email whether security updates are pending as well as basic
system statistics.
