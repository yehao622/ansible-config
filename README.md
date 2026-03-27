# Ansible GCP Server Automation

> 🚧 **Actively maintained** — This repo reflects my ongoing journey learning DevOps and infrastructure automation. New roles and improvements are added regularly.

Automated provisioning and configuration management for a GCP Linux server using **Ansible**, covering security hardening, web serving, zero-downtime deployments, monitoring, and VPN setup.

---

## 🏗️ Architecture Overview

```
Local Machine (Ansible Control Node)
        │
        │  SSH (key-based auth)
        ▼
GCP VM — Ubuntu (Managed Node)
        ├── UFW Firewall (ports 22, 80, 443, 51820)
        ├── fail2ban (brute-force protection)
        ├── Nginx (reverse proxy / web server)
        ├── Docker + Docker Compose
        │     ├── Monitoring Stack (Prometheus / Grafana)
        │     └── Blue-Green Deployment Stack
        └── WireGuard VPN (multi-peer, UDP 51820)
```

---

## 📁 Repository Structure

```
ansible-config/
├── setup.yml                  # Master playbook — orchestrates all roles
├── inventory.ini.example      # Inventory template (credentials excluded)
├── .gitignore                 # Prevents secrets from being committed
└── roles/
    ├── base/                  # System bootstrap & security hardening
    ├── nginx/                 # Nginx install & Jinja2 template config
    ├── app/                   # Application deployment
    ├── ssh/                   # SSH key injection & hardening
    ├── monitoring/            # Docker-based monitoring stack
    └── blue-green/            # Zero-downtime blue-green deployment
```

---

## ⚙️ Roles Breakdown

### `base` — System Bootstrap & Security Hardening
- Updates and upgrades all apt packages on every run (`dist` upgrade)
- Installs essential utilities: `curl`, `wget`, `git`, `vim`, `htop`, `unzip`
- Installs and enables **fail2ban** for SSH brute-force protection
- Configures **UFW firewall** with default-deny policy, allowing only ports 22/TCP, 80/TCP, 443/TCP

### `nginx` — Web Server & Reverse Proxy
- Installs Nginx and deploys configuration from a **Jinja2 template** (`nginx.conf.j2`)
- Enables the site via symlink (`sites-available` → `sites-enabled`)
- Uses Ansible **handlers** to restart Nginx only on config changes

### `ssh` — SSH Key Hardening
- Ensures `.ssh` directory exists with strict `0700` permissions
- Injects SSH public key into `authorized_keys` using the `authorized_key` module
- Key loaded dynamically via `lookup('file', '~/.ssh/gcp_ansible.pub')` — no hardcoded secrets

### `monitoring` — Docker-Based Monitoring Stack
- Installs Docker (`docker.io`) and Docker Compose v2 plugin
- Copies and launches a monitoring stack (Prometheus / Grafana) via `docker compose up -d`
- Enables Docker service at boot for persistence across VM restarts

### `blue-green` — Zero-Downtime Deployment
- Implements **blue-green deployment** strategy to eliminate downtime during app updates
- Copies deployment stack and `switch.sh` script to `/opt/blue-green/` on the server
- Launches the stack with Docker Compose; traffic switching handled by `switch.sh`

### `app` — Application Deployment
- Deploys application files to `/var/www/html` on the managed node

---

## 🚀 Usage

### Prerequisites
- Ansible installed on your local machine (`pip install ansible`)
- SSH key pair configured for GCP VM access
- GCP VM running Ubuntu 20.04+

### Setup
```bash
# Clone the repo
git clone https://github.com/yehao622/ansible-config.git
cd ansible-config

# Create your inventory from the example
cp inventory.ini.example inventory.ini
# Edit inventory.ini with your GCP VM's IP and SSH key path

# Run the full playbook
ansible-playbook -i inventory.ini setup.yml

# Run specific roles only using tags
ansible-playbook -i inventory.ini setup.yml --tags base
ansible-playbook -i inventory.ini setup.yml --tags nginx,app
ansible-playbook -i inventory.ini setup.yml --tags monitoring
ansible-playbook -i inventory.ini setup.yml --tags blue-green
```

---

## 🔒 Security Practices

- `inventory.ini` is **gitignored** — only `inventory.ini.example` is committed
- SSH private keys never stored in the repo; loaded dynamically at runtime
- UFW configured with **default-deny** policy — only explicitly allowed ports are open
- `fail2ban` blocks repeated failed SSH login attempts automatically
- WireGuard uses **public key cryptography** — pre-shared keys never transmitted in plaintext

---

## 🌐 WireGuard VPN (Manual Setup — Ansible Role In Progress)

A WireGuard VPN server is configured on the GCP VM, enabling secure encrypted tunneling from any client device.

**Current setup (manually verified working):**
- Server: GCP VM (`10.0.0.1`) listening on UDP `51820`
- Client 1: Laptop (`10.0.0.2`) — full tunnel (`0.0.0.0/0`), routes all traffic through GCP
- Multi-peer support ready (phone, additional devices on `10.0.0.3+`)
- UFW rule for `51820/udp` and `iptables` MASQUERADE for NAT configured

> 📌 **Planned**: Migrate WireGuard setup into a dedicated Ansible role (`roles/wireguard`) for fully automated provisioning.

---

## 🛠️ Tech Stack

| Category | Tools |
|---|---|
| Infrastructure | Google Cloud Platform (GCP) |
| Configuration Management | Ansible |
| Web Server | Nginx |
| Containerization | Docker, Docker Compose v2 |
| Monitoring | Prometheus, Grafana |
| VPN | WireGuard |
| Firewall | UFW, iptables |
| Security | fail2ban, SSH key auth |
| OS | Ubuntu 20.04+ |

---

## 📈 Roadmap

- [x] Add dedicated `roles/wireguard` for fully automated VPN provisioning ✅
- [x] Add GitHub Actions CI to lint playbooks with `ansible-lint` ✅
- [ ] Add `molecule` tests for role validation
- [ ] Add SSL/TLS automation with Certbot (Let's Encrypt)
- [ ] Expand monitoring stack with alerting rules

---

## 📄 License

MIT — feel free to use this as a reference for your own infrastructure automation.
