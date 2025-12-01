# Quick Start Guide - Fresh Proxmox VE 9.1 Installation

**Complete deployment from USB to running services in ~2 hours**

---

## 📋 Overview

This guide will walk you through:
1. Installing Proxmox VE 9.1 from USB
2. Configuring network with VLANs
3. Setting up ZFS storage pools
4. Installing automation tools (Packer, Terraform, Ansible)
5. Building your first VM template
6. Deploying Phase 1 services

**Total time**: ~2 hours (including 30-minute Packer build)

---

## ✅ Pre-Flight Checklist

### What You Need

- [ ] **USB drive** with Proxmox VE 9.1 ISO (see [PROXMOX_INSTALL_GUIDE.md](./PROXMOX_INSTALL_GUIDE.md))
- [ ] **Static IP info**: IP, gateway, DNS for Proxmox host
- [ ] **Hostname**: e.g., `pve.homelab.local` or `duality.homelab.local`
- [ ] **Email address**: For system notifications
- [ ] **Network plan**: Decide if using VLANs (see [NETWORK_SETUP.md](./NETWORK_SETUP.md))

### Information to Have Ready

```
Static IP:     192.168.1.200
Subnet:        /24 (255.255.255.0)
Gateway:       192.168.1.1
DNS:           1.1.1.1
Hostname:      pve.homelab.local
Root Password: (strong password)
Email:         your-email@example.com
```

---

## 🚀 Phase 1: Install Proxmox VE (30 minutes)

### Step 1: Boot from USB

1. Insert USB drive
2. Boot from USB (F12/F11/Delete for boot menu)
3. Select **Install Proxmox VE (Graphical)**

### Step 2: Configure Installation

**Target Disk:**
- Filesystem: **ZFS (RAID0)** (single disk) or **ZFS (RAID1)** (mirror)
- Select your OS disk (SSD recommended, 32GB+)
- Options: `ashift=12`, `compress=lz4`, `checksum=on`

**Location:**
- Country, time zone, keyboard layout

**Password & Email:**
- Root password: (strong password)
- Email: your-email@example.com

**Network:**
```
Hostname (FQDN):  pve.homelab.local
IP Address (CIDR): 192.168.1.200/24
Gateway:          192.168.1.1
DNS Server:       1.1.1.1
```

### Step 3: Install & Reboot

- Click **Install** → Wait 5-15 minutes → Remove USB → Reboot

### Step 4: Access Web UI

1. Open browser: `https://192.168.1.200:8006`
2. Accept certificate warning
3. Login:
   - User: `root`
   - Realm: `Linux PAM standard authentication`
   - Password: (your root password)

---

## 🔧 Phase 2: Post-Install Configuration (20 minutes)

### Option A: Automated Script (Recommended)

```bash
# SSH to Proxmox
ssh root@192.168.1.200

# Clone repository (or upload via SCP)
cd /root
git clone https://github.com/yourusername/-homelab.automation.git
cd -homelab.automation

# Run post-install script
chmod +x scripts/proxmox-post-install.sh
./scripts/proxmox-post-install.sh
```

**Script will:**
- ✓ Remove subscription notice
- ✓ Update system
- ✓ Install utilities
- ✓ Configure repositories
- ✓ Enable IOMMU (optional)
- ✓ Create API token
- ✓ Generate SSH keys
- ✓ Configure email (optional)

### Option B: Manual Steps

See [PROXMOX_INSTALL_GUIDE.md](./PROXMOX_INSTALL_GUIDE.md) Part 2 for manual instructions.

---

## 💾 Phase 3: ZFS Storage Pool (10 minutes)

**Skip this if you only have one disk (OS is already on ZFS)**

### For Additional Data Disks:

```bash
# List disks
lsblk

# Create ZFS pool (example: /dev/sdb)
zpool create -f \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O relatime=on \
  -m /mnt/vm-storage \
  vm-storage /dev/sdb

# Add to Proxmox storage
pvesm add zfspool vm-storage --pool vm-storage --content rootdir,images

# Verify
zpool status
pvesm status
```

**For mirrored pool (2 disks):**
```bash
zpool create -f -o ashift=12 -O compression=lz4 \
  vm-storage mirror /dev/sdb /dev/sdc
```

---

## 🌐 Phase 4: Network Configuration (15 minutes)

### Simple Setup (No VLANs)

**Default Proxmox setup works out of the box:**
- `vmbr0` = Management + VM network

**Skip to Phase 5**

### Advanced Setup (With VLANs)

**See [NETWORK_SETUP.md](./NETWORK_SETUP.md) for complete guide.**

**Quick VLAN Setup:**

Edit `/etc/network/interfaces`:

```bash
# Management (no VLAN)
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.200/24
    gateway 192.168.1.1
    bridge-ports enp0s31f6
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

# Services (VLAN 10)
auto vmbr10
iface vmbr10 inet static
    address 192.168.10.1/24
    bridge-ports vmbr0.10
    bridge-stp off

# IoT (VLAN 20)
auto vmbr20
iface vmbr20 inet static
    address 192.168.20.1/24
    bridge-ports vmbr0.20
    bridge-stp off
```

Apply:
```bash
ifreload -a
```

---

## 🛠️ Phase 5: Install Automation Tools (10 minutes)

```bash
cd /root/-homelab.automation

# Run installation script
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh
```

**Manual verification:**
```bash
packer version      # Should show Packer 1.x
terraform version   # Should show Terraform 1.x
ansible --version   # Should show Ansible 2.x
```

---

## 🔐 Phase 6: Configuration Files (10 minutes)

### Step 1: Create Terraform Variables

```bash
cd /root/-homelab.automation/terraform

# Copy example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Fill in:**
```hcl
# API token (created by post-install script)
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# SSH public key (from /root/.ssh/id_rsa.pub)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."

# Rest of the values should be correct by default
```

**Get API token secret:**
```bash
# If you didn't save it, create a new one:
pveum user token add root@pam terraform --privsep 0
```

**Get SSH public key:**
```bash
cat /root/.ssh/id_rsa.pub
```

### Step 2: Create Ansible Vault

```bash
cd /root/-homelab.automation/ansible

# Generate vault password
openssl rand -base64 32 > vault_password.txt
chmod 600 vault_password.txt

# Create encrypted vault
ansible-vault create group_vars/vault.yml
# Enter password from vault_password.txt when prompted
```

**Add to vault (use password from vault_password.txt):**
```yaml
---
# Sample secrets - customize as needed
vault_mysql_root_password: "changeme123"
vault_nextcloud_admin_password: "changeme123"
vault_gitea_admin_password: "changeme123"
vault_semaphore_admin_password: "changeme123"
```

Save and exit (`:wq` in vim)

---

## 📦 Phase 7: Build Packer Template (30 minutes)

**This creates the base Ubuntu 22.04 template for all VMs**

```bash
cd /root/-homelab.automation/packer

# Validate template
packer validate -var "pm_password=dummy" ubuntu-22.04-lts.pkr.hcl

# Build template (will prompt for password)
read -sp 'Proxmox Password: ' PM_PASSWORD
packer build -var "pm_password=$PM_PASSWORD" ubuntu-22.04-lts.pkr.hcl
```

**Wait 20-30 minutes** - Packer will:
1. Download Ubuntu 22.04 ISO (if not cached)
2. Create temporary VM
3. Install Ubuntu unattended
4. Install qemu-guest-agent and cloud-init
5. Clean up and convert to template
6. Delete temporary VM

**Result:** Template named `ubuntu-2204-cloudinit-template` appears in Proxmox

---

## 🚀 Phase 8: Deploy Test VM (5 minutes)

**Validate the entire workflow: Packer → Terraform → Ansible**

### Step 1: Activate Test VM in Terraform

```bash
cd /root/-homelab.automation/terraform/vms

# Copy and uncomment example
cp vm-test.tf.example vm-test.tf
nano vm-test.tf

# Uncomment all lines (remove the leading #)
```

### Step 2: Deploy with Terraform

```bash
cd /root/-homelab.automation/terraform

# Initialize (first time only)
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
# Type "yes" when prompted
```

**Wait 2-3 minutes** for VM creation and cloud-init to complete.

### Step 3: Configure with Ansible

```bash
cd /root/-homelab.automation/ansible

# Test connectivity
ansible all -m ping

# Run configuration
ansible-playbook playbooks/site.yml
```

**Expected output:**
```
test-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 4: Verify VM

```bash
# SSH to test VM
ssh admin@192.168.1.230

# Check Docker (should be installed by Ansible)
docker --version
```

---

## ✅ Validation Checklist

After completing all phases, verify:

- [ ] Proxmox web UI accessible at `https://192.168.1.200:8006`
- [ ] No subscription notice on login
- [ ] ZFS pool created and visible in Datacenter → Storage
- [ ] API token created (check with `pveum user token list root@pam`)
- [ ] SSH key exists at `/root/.ssh/id_rsa.pub`
- [ ] Packer installed (`packer version`)
- [ ] Terraform installed (`terraform version`)
- [ ] Ansible installed (`ansible --version`)
- [ ] `terraform.tfvars` file created with API token and SSH key
- [ ] `ansible/vault_password.txt` created (chmod 600)
- [ ] `ansible/group_vars/vault.yml` encrypted vault exists
- [ ] Packer template `ubuntu-2204-cloudinit-template` exists in Proxmox
- [ ] Test VM deployed and accessible via SSH
- [ ] Ansible playbook runs successfully
- [ ] Test VM has Docker installed

---

## 🎯 Next Steps - Phase 1 Deployment

**Now that the foundation is validated, deploy Phase 1 services:**

### Phase 1 Services:
1. **Gitea** - Self-hosted Git server
2. **Semaphore** - Ansible/Terraform UI
3. Additional VMs as needed

**See:**
- `docs/SERVICE_DEPLOYMENT.md` (coming soon)
- `SERVICE_CATALOG.md` for service inventory

**To deploy Phase 1:**

1. Create Terraform VM definitions for Gitea, Semaphore
2. Create Ansible roles for service configuration
3. Deploy with Terraform
4. Configure with Ansible
5. Migrate this repository to self-hosted Gitea

---

## 🆘 Troubleshooting

### Proxmox Web UI Not Accessible

```bash
# Check IP configuration
ip addr show

# Check if pveproxy is running
systemctl status pveproxy

# Restart web service
systemctl restart pveproxy
```

### Packer Build Fails

```bash
# Ensure ISO is downloaded
ls -lh /var/lib/vz/template/iso/

# Check Proxmox password is correct
pveum passwd root@pam

# Validate template
packer validate -var "pm_password=test" ubuntu-22.04-lts.pkr.hcl
```

### Terraform Apply Fails

```bash
# Check API token
pveum user token list root@pam

# Verify terraform.tfvars has correct values
cat terraform/terraform.tfvars

# Re-initialize
cd terraform
terraform init -upgrade
```

### Ansible Can't Connect to VMs

```bash
# Wait 2-3 minutes for cloud-init to complete
sleep 180

# Test manual SSH
ssh admin@192.168.1.230

# Check inventory
cat ansible/inventory/hosts.yml

# Test ping
ansible all -m ping -vvv
```

### SSH Key Permission Denied

```bash
# Verify SSH key is in terraform.tfvars
cat terraform/terraform.tfvars | grep ssh_public_key

# Verify SSH private key exists
ls -la ~/.ssh/id_rsa

# Test SSH with key
ssh -i ~/.ssh/id_rsa admin@192.168.1.230
```

---

## 📚 Additional Documentation

- **[PROXMOX_INSTALL_GUIDE.md](./PROXMOX_INSTALL_GUIDE.md)** - Detailed Proxmox installation
- **[NETWORK_SETUP.md](./NETWORK_SETUP.md)** - VLAN and network configuration
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Network design and resource planning
- **[SERVICE_CATALOG.md](../SERVICE_CATALOG.md)** - Service inventory
- **[README.md](../README.md)** - Project overview

---

## 🎉 Success!

If you've completed all validation checks, congratulations! You now have:

✅ Proxmox VE 9.1 installed and configured
✅ ZFS storage pools ready
✅ Network configured (with or without VLANs)
✅ Automation tools installed (Packer, Terraform, Ansible)
✅ Base VM template built
✅ Configuration files created (terraform.tfvars, vault.yml)
✅ Test VM deployed and validated
✅ Full IaC workflow proven end-to-end

**You're ready to deploy Phase 1 services!**

---

**Quick Start Guide Version**: 1.0
**Last Updated**: 2025-12-01
**Environment**: Proxmox VE 9.1
**Author**: Automated Homelab Project
