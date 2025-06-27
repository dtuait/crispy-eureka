#!/usr/bin/env python3
"""Send a status email about system updates and resource usage."""

import os
import shutil
import socket
import subprocess
from email.message import EmailMessage
from pathlib import Path
import smtplib
import psutil


def load_env() -> None:
    env_path = Path(__file__).with_name(".env.local")
    if env_path.exists():
        with env_path.open() as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                os.environ.setdefault(key, value)
    else:
        print("⚠️  .env.local not found – falling back on existing env vars")


def system_stats():
    hostname = socket.gethostname()
    uptime = subprocess.run(["uptime", "-p"], text=True, capture_output=True).stdout.strip() or "N/A"
    load = (
        subprocess.run(["uptime"], text=True, capture_output=True)
        .stdout.split("load average:")[-1]
        .strip()
        or "N/A"
    )

    mem = psutil.virtual_memory()
    mem_usage = f"{mem.used // (1024**2)}/{mem.total // (1024**2)} MB used ({mem.percent}%)"

    du = shutil.disk_usage("/")
    disk_percent = round(du.used / du.total * 100)
    disk_usage = f"{du.used // (1024**3)}/{du.total // (1024**3)} GB used ({disk_percent}%)"
    if disk_percent >= 80:
        disk_usage += " [***IMPORTANT***]"

    return hostname, uptime, load, mem_usage, disk_usage


def security_updates() -> str:
    subprocess.run(["sudo", "apt-get", "update", "-qq"], check=False)
    result = subprocess.run(
        "apt list --upgradable 2>/dev/null | grep -c '-security'",
        shell=True,
        text=True,
        capture_output=True,
    )
    try:
        count = int(result.stdout.strip())
    except ValueError:
        count = 0
    if count > 0:
        return f"[{count} SECURITY UPDATES PENDING]"
    return "[Server is up-to-date]"


def send_mail(body: str) -> None:
    msg = EmailMessage()
    msg["Subject"] = os.environ.get("MAIL_SUBJECT", "System Status")
    msg["From"] = os.environ["FROM_ADDR"]
    msg["To"] = os.environ["TO_ADDR"]
    msg.set_content(body)

    server = os.environ["SMTP_SERVER"]
    port = int(os.environ.get("SMTP_PORT", 587))
    user = os.environ.get("SMTP_USER")
    password = os.environ.get("SMTP_PASS")

    with smtplib.SMTP(server, port) as smtp:
        smtp.starttls()
        if user:
            smtp.login(user, password)
        smtp.send_message(msg)



def main() -> None:
    load_env()
    hostname, uptime, load, mem, disk = system_stats()
    sec = security_updates()

    body = (
        "Vaultwarden Backup Summary\n"
        "==========================\n\n"
        f"Host: {hostname}\n"
        "---------------------------\n"
        f"Uptime:       {uptime}\n"
        f"CPU Load:     {load}\n"
        f"Memory Usage: {mem}\n"
        f"Disk Usage:   {disk}\n"
        f"Security:     {sec}\n"
    )

    send_mail(body)
    print("✔ Email sent from", os.environ.get("FROM_ADDR"), "to", os.environ.get("TO_ADDR"))


if __name__ == "__main__":
    main()
