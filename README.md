# Ansible GCP Server Automation

> 🚧 **Actively maintained** — This repo reflects my ongoing journey learning DevOps and infrastructure automation. New roles and improvements are added regularly.

Automated provisioning and configuration management for a GCP Linux server using **Ansible**, covering security hardening, web serving, zero-downtime deployments, SSL/TLS automation, monitoring with alerting, and VPN setup.

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
        ├── Certbot (Let's Encrypt SSL/TLS — auto-renewing)
        ├── Docker + Docker Compose
        │     ├── Monitoring Stack (Prometheus / Grafana / Alertmanager)
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
    ├── blue-green/            # Zero-downtime blue-green deployment
    ├── wireguard/             # WireGuard VPN provisioning
    └── certbot/               # SSL/TLS automation via Let's Encrypt
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

### `certbot` — SSL/TLS Automation
- Installs Certbot via snap (recommended by Let's Encrypt)
- Obtains a TLS certificate for the domain from Let's Encrypt non-interactively
- Configures Nginx for HTTPS automatically
- Enables `snap.certbot.renew.timer` for fully automated 90-day certificate renewal

### `ssh` — SSH Key Hardening
- Ensures `.ssh` directory exists with strict `0700` permissions
- Injects SSH public key into `authorized_keys` using the `authorized_key` module
- Key loaded dynamically via `lookup('file', '~/.ssh/gcp_ansible.pub')` — no hardcoded secrets

### `monitoring` — Docker-Based Monitoring Stack
- Installs Docker (`docker.io`) and Docker Compose v2 plugin
- Deploys Prometheus, Grafana, Alertmanager, and node-exporter via `docker compose up -d`
- Enables Docker service at boot for persistence across VM restarts
- Includes 3 Prometheus alerting rules loaded from `alert_rules.yml`:
  - `InstanceDown` — fires if a target is unreachable for > 1 minute (critical)
  - `HighCpuUsage` — fires if CPU exceeds 80% for > 2 minutes (warning)
  - `HighMemoryUsage` — fires if RAM exceeds 85% for > 2 minutes (warning)

### `blue-green` — Zero-Downtime Deployment
- Implements **blue-green deployment** strategy to eliminate downtime during app updates
- Copies deployment stack and `switch.sh` script to `/opt/blue-green/` on the server
- Launches the stack with Docker Compose; traffic switching handled by `switch.sh`

### `wireguard` — VPN Server
- Installs WireGuard and provisions a VPN server on the GCP VM (`10.0.0.1`, UDP `51820`)
- Generates server keypair and deploys `wg0.conf` via Ansible template
- Configures UFW rule for `51820/udp` and iptables NAT masquerading
- Multi-peer support: laptop (`10.0.0.2`), additional devices (`10.0.0.3+`)
- Enables and starts `wg-quick@wg0` service for persistence across reboots

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
ansible-playbook -i inventory.ini setup.yml --tags wireguard
ansible-playbook -i inventory.ini setup.yml --tags blue-green
```

🧪 Testing & CI
  GitHub Actions runs ansible-lint on every push to validate all playbooks and roles
  Molecule tests the base role in an isolated environment to verify idempotency and task correctness

---

## 🔒 Security Practices

- `inventory.ini` is **gitignored** — only `inventory.ini.example` is committed
- SSH private keys never stored in the repo; loaded dynamically at runtime
- UFW configured with **default-deny** policy — only explicitly allowed ports are open
- `fail2ban` blocks repeated failed SSH login attempts automatically
- WireGuard uses **public key cryptography** — pre-shared keys never transmitted in plaintext
- HTTPS enforced via Let's Encrypt certificate with automated renewal

---

## 🛠️ Tech Stack

| Category                 | Tools                                            |
| ------------------------ | ------------------------------------------------ |
| Infrastructure           | Google Cloud Platform (GCP)                      |
| Configuration Management | Ansible                                          |
| Web Server               | Nginx                                            |
| SSL/TLS                  | Certbot, Let's Encrypt                           |
| Containerization         | Docker, Docker Compose v2                        |
| Monitoring               | Prometheus, Grafana, Alertmanager, node-exporter |
| VPN                      | WireGuard                                        |
| Firewall                 | UFW, iptables                                    |
| Security                 | fail2ban, SSH key auth                           |
| CI                       | GitHub Actions (ansible-lint)                    |
| Testing                  | Molecule                                         |
| OS                       | Ubuntu 20.04+                                    |

---

## 📈 Roadmap

- [x] Add dedicated `roles/wireguard` for fully automated VPN provisioning ✅
- [x] Add GitHub Actions CI to lint playbooks with `ansible-lint` ✅
- [x] Add `molecule` tests for role validation ✅
- [x] Add SSL/TLS automation with Certbot (Let's Encrypt) ✅
- [x] Expand monitoring stack with alerting rules ✅

---

## 📄 License

MIT — feel free to use this as a reference for your own infrastructure automation.
