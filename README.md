*This project has been created as a self-directed portfolio project by itanvuia*

# 🔨 ForgeStack

> **Infrastructure as Code**
>
> *"Don't repeat yourself — automate yourself."*
>
> — Every engineer who configured the same server twice

![42 School](https://img.shields.io/badge/42-000000?style=for-the-badge&logo=42&logoColor=white)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)](https://www.debian.org/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Hyper--V](https://img.shields.io/badge/Hyper--V-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/)
[![Shell](https://img.shields.io/badge/Shell_Script-737373?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

---

## 📖 About this Project

ForgeStack takes everything learned in [Born2beRoot](https://github.com/Axel92803/Born2beRoot) and encodes it as **reproducible, version-controlled automation**. Instead of configuring a server by hand (running commands, editing files, hoping you remember every step) you write declarative Ansible playbooks that describe the desired state. One command provisions a fully hardened Linux server from a minimal install.

The project targets **both Debian and Arch Linux** from a single codebase, using Ansible's conditional task execution and OS-specific group variables to handle the differences between distributions.

This is Phase 1 of a two-phase project. Phase 2 will extend this hardened base to deploy a **containerised AI inference server** (Ollama + reverse proxy + authentication) on top of the same infrastructure.

**Configuration management:** Ansible
**Target OS:** Debian 13 (Trixie) + Arch Linux
**Virtualisation:** Hyper-V (dual-adapter networking)
**Control node:** WSL2 Ubuntu via VS Code

---

## 📑 Table of Contents

- [🤔 Why Ansible](#-why-ansible)
- [🏗️ Architecture](#️-architecture)
- [📂 Project Structure](#-project-structure)
- [⚙️ Roles Overview](#️-roles-overview)
- [🔧 Prerequisites](#-prerequisites)
- [🚀 Getting Started](#-getting-started)
- [🔍 Verification](#-verification)
- [🗺️ Roadmap](#️-roadmap)
- [📚 Resources](#-resources)
- [🧠 Design Decisions](#-design-decisions)

---

## 🤔 Why Ansible

The project needed a configuration management tool. Ansible won for three reasons:

**Agentless.** Ansible connects over SSH: no daemon, no client software on the target. The VM needs nothing installed beyond what a minimal OS ships with (plus Python on Arch). This is the same SSH connection I already learned from Born2beRoot.

**Declarative YAML.** Playbooks describe *what* the server should look like, not *how* to get there. You can read an Ansible role without a manual. More importantly, a recruiter or colleague can read it too.

**Idempotent.** Running the same playbook twice produces zero changes on the second run. This is the single most important property of good infrastructure automation, it means your playbooks are safe to run at any time, against any state, and the result is always the same.

### ⚖️ Ansible vs Alternatives

| | **Ansible** | **Terraform** | **Puppet / Chef** |
|---|---|---|---|
| **Purpose** | Configuration management (what's *on* the server) | Infrastructure provisioning (the server *itself*) | Configuration management |
| **Agent required** | No — SSH only | No — API-based | Yes — agent on every node |
| **Language** | YAML | HCL | Ruby DSL |
| **Learning curve** | Low | Medium | High |
| **Idempotent** | Yes (with proper modules) | Yes (declarative by design) | Yes |
| **Best for** | Server configuration, application deployment | Cloud resources, VMs, networking | Large-scale enterprise fleet management |

Ansible handles configuration; Terraform handles provisioning. They complement each other. See the [Roadmap](#️-roadmap) for plans to add a Terraform layer.

---

## 🏗️ Architecture

```
                              ┌──────────────────────────────┐
                              │        HYPER-V HOST          │
                              │        (Windows 11)          │
                              │                              │
┌───────────────────┐   SSH   │  ┌────────────────────────┐  │
│   CONTROL NODE    │─────────┼─▶│   forgestack-deb       │ │
│                   │         │  │   Debian 12 Minimal     │ │
│   WSL2 Ubuntu     │         │  │   192.168.50.10         │ │
│   Ansible         │         │  └────────────────────────┘  │
│   VS Code + WSL   │         │                              │
│                   │   SSH   │  ┌────────────────────────┐  │
│   ~/forgestack/   │─────────┼─▶│   forgestack-arch      │ │
│     playbooks/    │         │  │   Arch Linux            │ │
│     roles/        │         │  │   192.168.50.20         │ │
│     inventory/    │         │  └────────────────────────┘  │
└───────────────────┘         │                              │
                              └──────────────────────────────┘

Network Layout:
  Internal Switch (ForgeStack) 192.168.50.0/24 ─── Ansible traffic
  Default Switch (DHCP) ─────────────────────── Internet access
```

The control node (WSL2) sends Ansible commands over SSH to both targets. Each VM has two network adapters: an **Internal Switch** with a static IP for Ansible (predictable, never changes) and a **Default Switch** for internet access (DHCP, used for package downloads). The playbook targets `all` hosts and uses OS-specific conditionals and group variables to handle differences between distributions.

---

## 📂 Project Structure

```
forgestack/
├── ansible.cfg                   # Ansible configuration (roles path, inventory)
├── inventory/
│   ├── hosts.yml                 # Multi-OS target inventory
│   └── group_vars/
│       ├── all.yml               # Shared variables (users, sudo, password policy)
│       ├── debian.yml            # Debian-specific packages
│       └── arch.yml              # Arch-specific packages
├── playbooks/
│   └── site.yml                  # Master playbook — targets all hosts
├── roles/
│   ├── base/                     # OS updates, essential packages, hostname, timezone
│   │   └── tasks/
│   │       └── main.yml
│   ├── users/                    # User creation, sudo, groups, password policy
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   └── templates/
│   │       ├── sudoers.j2        # Sudo rules template
│   │       └── pwquality.conf.j2 # Password complexity template (Arch)
│   ├── ssh/                      # SSH hardening (planned)
│   ├── firewall/                 # UFW / iptables rules (planned)
│   ├── security/                 # AppArmor enforcement (planned)
│   └── monitoring/               # Cron-based monitoring (planned)
└── README.md
```

Each role is self-contained with its own tasks, handlers, and templates. This structure is designed for extensibility. Phase 2 roles (`docker/`, `ollama/`, `reverse_proxy/`) will slot in alongside existing roles without modifying them.

---

## ⚙️ Roles Overview

| Role | What It Does | Multi-OS | Born2beRoot Equivalent |
|---|---|---|---|
| **base** | System updates, essential packages, hostname, timezone | ✅ `apt` / `pacman` conditionals | First steps after install |
| **users** | User accounts, groups, sudo rules, SSH keys, password policy | ✅ `pam.d` / `pwquality.conf` | User & group management, sudoers config |
| **ssh** | Custom port, key-only auth, root login disabled | 🔜 Planned | SSH hardening on port 4242 |
| **firewall** | Deny-all default, allow only SSH port | 🔜 Planned | UFW configuration |
| **security** | AppArmor enabled and enforcing at boot | 🔜 Planned | AppArmor setup |
| **monitoring** | Deploy monitoring script, configure cron schedule | 🔜 Planned | monitoring.sh + cron |

### 👥 User Architecture

The playbook provisions three accounts with scoped access, reflecting real-world access control patterns:

| User | Groups | Purpose |
|---|---|---|
| **alex** | `sudo`, `devops`, `sshusers` | Primary admin — full sudo, SSH access |
| **deploy** | `devops`, `sshusers` | Service account for automated deployments (CI/CD) |
| **monitoring** | `logging` | Restricted local account for monitoring stack — no SSH |

### 📦 Package Management

Packages are organised by function in OS-specific group variables, with categories for system administration, networking, editors, development tools, and maintenance utilities. The same Ansible tasks install the correct packages per distribution:

| Category | Debian | Arch |
|---|---|---|
| **Package manager** | `apt` | `pacman` |
| **SSH server** | `openssh-server` | `openssh` |
| **Build tools** | `build-essential` | `base-devel` |
| **Password quality** | `libpam-pwquality` | `pam` (built-in) |

---

## 🔧 Prerequisites

- **Ansible** installed on your control node (`pip install ansible` or `apt install ansible`)
- **Target machine(s)** running Debian 13 and/or Arch Linux minimal with SSH access
- **Python** on the target (Debian includes it; Arch requires `pacman -S python`)
- An **SSH key pair** deployed to the target (`ssh-copy-id`)
- **Git** for version control

---

## 🚀 Getting Started

### Clone the repo

```bash
git clone git@github.com:Axel92803/forgestack.git
cd forgestack
```

### Configure inventory

Update `inventory/hosts.yml` with your target IPs:

```yaml
all:
  children:
    debian:
      hosts:
        forgestack-deb:
          ansible_host: 192.168.50.10
          ansible_user: alex
          ansible_ssh_private_key_file: ~/.ssh/id_ed25519
    arch:
      hosts:
        forgestack-arch:
          ansible_host: 192.168.50.20
          ansible_user: alex
          ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

### Test connectivity

```bash
# All hosts
ansible all -m ping

# Specific OS group
ansible debian -m ping
ansible arch -m ping
```

### Run the playbook

```bash
# Provision all hosts
ansible-playbook playbooks/site.yml

# Target a specific group
ansible-playbook playbooks/site.yml --limit debian
ansible-playbook playbooks/site.yml --limit arch

# Dry run (preview changes without applying)
ansible-playbook playbooks/site.yml --check --diff
```

---

## 🔍 Verification

After a full playbook run, verify the server state:

```bash
# SSH into target
ssh alex@192.168.50.10    # Debian
ssh alex@192.168.50.20    # Arch

# Verify users and groups
id alex
id deploy
id monitoring
getent group devops
getent group sshusers
getent group logging

# Verify sudo configuration
sudo cat /etc/sudoers.d/forgestack

# Verify password policy
sudo chage -l alex
cat /etc/login.defs | grep PASS_

# Verify packages
which vim git tmux htop

# The real test — run the playbook again
ansible-playbook playbooks/site.yml
# Expected: zero changes
```

---

## 🗺️ Roadmap

### Phase 1 — Infrastructure as Code (current)

- [x] Project scaffold and Ansible connectivity
- [x] Multi-OS inventory (Debian + Arch Linux)
- [x] Base system role (updates, packages, hostname, timezone)
- [x] User and permission management role (users, groups, sudo, password policy)
- [ ] SSH hardening role
- [ ] Firewall configuration role
- [ ] AppArmor enforcement role
- [ ] Monitoring deployment role
- [ ] Full end-to-end validation on fresh VMs

### Phase 1 — Extras

- [ ] Ansible Vault for secrets management
- [ ] Molecule testing framework
- [ ] CI/CD pipeline via GitHub Actions
- [ ] Terraform provisioning layer
- [ ] Documentation site (MkDocs / GitHub Pages)

### Phase 2 — Containerised AI Inference Server (planned)

- [ ] Docker role
- [ ] Ollama deployment role
- [ ] Reverse proxy role (Nginx/Caddy + TLS)
- [ ] Authentication layer
- [ ] Health checks and logging

---

## 📚 Resources

### References

- [Ansible Documentation](https://docs.ansible.com/) — the canonical reference
- [Ansible for DevOps — Jeff Geerling](https://www.ansiblefordevops.com/) — best practical Ansible book
- [Jeff Geerling YouTube](https://www.youtube.com/@JeffGeerling) — video tutorials from beginner to advanced
- [Debian Administrator's Handbook](https://www.debian.org/doc/manuals/debian-handbook/) — comprehensive Debian guide
- [Arch Wiki](https://wiki.archlinux.org/) — best Linux documentation on the internet, useful regardless of distro
- [Ansible Galaxy](https://galaxy.ansible.com/) — community-contributed roles (study well-written ones for patterns)
- [Jinja2 Documentation](https://jinja.palletsprojects.com/) — template engine used by Ansible

---

## 🧠 Design Decisions

**Why Hyper-V over VirtualBox?** WSL2 requires Hyper-V's hypervisor platform, which degrades VirtualBox to a compatibility mode. Since Hyper-V is already running, using it natively avoids the performance penalty.

**Why dual-adapter networking?** Internal Switch provides a stable, predictable IP for Ansible (`192.168.50.10` / `.20`). Default Switch provides internet access for package downloads. Clean separation of concerns.

**Why Debian and Arch?** Debian is the direct continuation from Born2beRoot, familiar territory for learning Ansible. Arch is the opposite extreme: rolling release, no installer, everything manual. Supporting both from one codebase demonstrates real-world multi-platform automation and uses Ansible's `when:` conditionals and group variables extensively.

**Why this role structure?** Each role maps to a Born2beRoot requirement, making the progression from manual to automated explicit. Roles are self-contained so Phase 2 roles compose alongside them without refactoring.

**Why three users?** `alex` (admin), `deploy` (CI/CD service account), and `monitoring` (restricted local account) reflect how real teams structure access. Each has scoped permissions following the principle of least privilege, rather than giving every account full sudo.

**Why separate `group_vars` per OS?** Package names, file paths, and service names differ between distributions. Keeping OS-specific values in `debian.yml` and `arch.yml` while sharing everything else in `all.yml` means tasks reference the same variable names regardless of target, the right values get injected based on inventory group membership.

---

**Author:** Alex Tanvuia (Ionut Tanvuia)

**42 Login:** itanvuia

**School:** [42 London](https://42london.com/)

[![42 Profile](https://img.shields.io/badge/42_Profile-itanvuia-000000?style=flat-square&logo=42)](https://profile.intra.42.fr/)

*Built on the foundations of [Born2beRoot](https://github.com/Axel92803/Born2beRoot). Part of my journey through 42 School's peer-learning curriculum. Check out my other projects on my [GitHub profile](https://github.com/Axel92803)!*
