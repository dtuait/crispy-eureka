# crispy-eureka

This repository contains two helper scripts:

1. **setup_unattended_upgrades.sh** – installs and enables the Debian
   *unattended-upgrades* service.
2. **pull_vaultwarden_backups.py** – checks the local system for pending
   security updates and emails a short status report.  It is intended to run
   from cron.

## Getting started with Python

The backup notification script requires Python 3. Create a virtual
environment and install the dependencies so that modules such as
`psutil` are available:

```bash
sudo apt-get install python3-venv  # if not already installed
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Once activated, the `venv` directory contains the Python interpreter
and packages needed to run `pull_vaultwarden_backups.py`.

## Setting up unattended upgrades

Run the following with root privileges:

```bash
sudo ./setup_unattended_upgrades.sh
```

The script installs the required packages, enables the systemd service and
creates a basic `/etc/apt/apt.conf.d/20auto-upgrades` configuration so that
security updates are installed automatically.

## Notification script

The backup script runs from the virtual environment created in the
[Getting started with Python](#getting-started-with-python) section.
Activate the environment and then configure your mail settings.

Copy the provided `.env.example` to `.env.local` next to the script and
adjust the values to match your environment:

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
