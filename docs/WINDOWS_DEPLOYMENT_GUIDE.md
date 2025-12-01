# Windows 11 Deployment Guide

Complete guide for deploying the automated home lab infrastructure from a Windows 11 laptop to a fresh Proxmox VE installation.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Windows Environment Setup](#windows-environment-setup)
3. [Proxmox Initial Configuration](#proxmox-initial-configuration)
4. [SSH Key Setup](#ssh-key-setup)
5. [Tool Installation](#tool-installation)
6. [Repository Setup](#repository-setup)
7. [Phase 1: Build VM Template with Packer](#phase-1-build-vm-template-with-packer)
8. [Phase 2: Provision Infrastructure with Terraform](#phase-2-provision-infrastructure-with-terraform)
9. [Phase 3: Configure Services with Ansible](#phase-3-configure-services-with-ansible)
10. [Troubleshooting](#troubleshooting)
11. [Quick Reference](#quick-reference)

---

## Prerequisites

### Hardware Requirements
- **Windows 11 laptop** with:
  - 8 GB RAM minimum
  - 50 GB free disk space
  - Stable network connection
  - Administrator access

- **Proxmox VE server** with:
  - Proxmox VE 8.x installed
  - Network connectivity to Windows laptop
  - At least 100 GB storage available
  - Static IP address (recommended: 192.168.1.200)

### Network Requirements
- Both devices on same network or routable subnets
- Firewall allows:
  - SSH (port 22) to Proxmox
  - HTTPS (port 8006) for Proxmox Web UI
  - HTTP (port varies) for Packer during build

---

## Windows Environment Setup

### Option 1: WSL2 (Recommended)

**Why WSL2?**
- Native Linux environment on Windows
- Better compatibility with Ansible
- Easier SSH key management
- Familiar Linux commands

**Installation:**

1. **Enable WSL2**

   Open PowerShell as Administrator:
   ```powershell
   wsl --install
   ```

   Restart your computer when prompted.

2. **Install Ubuntu from Microsoft Store**

   ```powershell
   wsl --install -d Ubuntu-22.04
   ```

3. **Set up Ubuntu**

   After installation, launch Ubuntu and create a user:
   ```bash
   # Enter username and password when prompted
   # Update system
   sudo apt update && sudo apt upgrade -y
   ```

4. **Configure WSL2 Resources** (Optional)

   Create `%USERPROFILE%\.wslconfig`:
   ```ini
   [wsl2]
   memory=4GB
   processors=2
   ```

### Option 2: Native Windows Tools

**Alternative if you prefer native Windows:**
- Git for Windows (includes Git Bash)
- Terraform (Windows binary)
- Packer (Windows binary)
- Ansible via Python pip or Docker

**Note:** The rest of this guide assumes WSL2 for consistency with Linux commands.

---

## Proxmox Initial Configuration

### 1. Access Proxmox Web UI

Open browser on Windows laptop:
```
https://192.168.1.200:8006
```

Login with `root` and your password.

### 2. Create API Token for Automation

**Via Web UI:**
1. Navigate to **Datacenter** → **Permissions** → **API Tokens**
2. Click **Add**
3. User: `root@pam`
4. Token ID: `terraform`
5. **Uncheck** "Privilege Separation"
6. Click **Add**

**⚠️ IMPORTANT:** Copy the token secret immediately - it won't be shown again!

**Save credentials for later:**
```
Token ID: root@pam!terraform
Secret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 3. Verify Storage Configuration

**Check storage pools:**
1. Navigate to **Datacenter** → **Storage**
2. Verify you have:
   - `local` - for ISO images
   - `local-zfs` or `local-lvm` - for VM disks

**Note:** Update `packer/ubuntu-22.04-lts.pkr.hcl` if your storage names differ.

### 4. Upload Ubuntu ISO (Optional)

Packer can download the ISO automatically, but pre-uploading is faster:

1. Navigate to **local** storage → **ISO Images**
2. Click **Upload** or **Download from URL**
3. URL: `https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso`

### 5. Configure Network (if needed)

**Verify bridge configuration:**
1. Select your Proxmox node → **Network**
2. Ensure `vmbr0` exists and is configured
3. Note the bridge name (update `packer/ubuntu-22.04-lts.pkr.hcl` if different)

---

## SSH Key Setup

### 1. Generate SSH Key Pair (in WSL2)

```bash
# Launch WSL2
wsl

# Generate new SSH key
ssh-keygen -t rsa -b 4096 -C "homelab-automation"

# Press Enter to accept default location (~/.ssh/id_rsa)
# Enter a passphrase (optional but recommended)
```

### 2. Copy SSH Key to Proxmox

```bash
# Copy public key to Proxmox
ssh-copy-id root@192.168.1.200

# Enter Proxmox root password when prompted
```

### 3. Test SSH Connection

```bash
# Should connect without password prompt (or with passphrase if set)
ssh root@192.168.1.200

# Exit back to WSL
exit
```

### 4. Add SSH Key to Repository

This key will be injected into VMs via cloud-init:

```bash
# Display your public key
cat ~/.ssh/id_rsa.pub

# Copy the output (starts with ssh-rsa)
```

**Save this - you'll need it for `terraform.tfvars` later.**

---

## Tool Installation

All commands below are run in **WSL2 Ubuntu terminal**.

### 1. Install Git

```bash
sudo apt update
sudo apt install git -y

# Verify
git --version
```

### 2. Install Packer

```bash
# Download and install HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Packer
sudo apt update
sudo apt install packer -y

# Verify
packer version
```

### 3. Install Terraform

```bash
# Already added HashiCorp repo above, just install
sudo apt install terraform -y

# Verify
terraform version
```

### 4. Install Ansible

```bash
# Install dependencies
sudo apt install software-properties-common -y

# Add Ansible PPA
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install ansible -y

# Verify
ansible --version
```

### 5. Install Additional Tools

```bash
# Useful for automation
sudo apt install -y \
  curl \
  wget \
  jq \
  unzip \
  python3-pip \
  sshpass

# Install Ansible Docker modules (for future use)
ansible-galaxy collection install community.docker
```

---

## Repository Setup

### 1. Clone Repository

```bash
# Navigate to home directory
cd ~

# Clone the repository
git clone https://github.com/vjspal/-homelab.automation.git

# Or if using SSH:
# git clone git@github.com:vjspal/-homelab.automation.git

# Navigate into repository
cd -homelab.automation

# Checkout the feature branch
git checkout claude/review-prd-documents-0174QMQzsuEaZsEPtKrotsBT
```

### 2. Verify Repository Structure

```bash
# Should see all Phase 0 files
ls -la

# Expected output:
# .gitignore
# README.md
# ARCHITECTURE.md
# SERVICE_CATALOG.md
# packer/
# terraform/
# ansible/
```

---

## Phase 1: Build VM Template with Packer

### 1. Navigate to Packer Directory

```bash
cd ~/homelab.automation/packer
```

### 2. Review Packer Configuration

**Verify these settings in `ubuntu-22.04-lts.pkr.hcl`:**

```bash
# Check Proxmox API URL
grep "pm_api_url" ubuntu-22.04-lts.pkr.hcl
# Should show: https://192.168.1.200:8006/api2/json

# Check node name
grep "pm_node" ubuntu-22.04-lts.pkr.hcl
# Should match your Proxmox node name (default: duality)

# Check storage pools
grep "disk_store\|iso_store" ubuntu-22.04-lts.pkr.hcl
# Verify these match your Proxmox storage
```

**If any values are incorrect, edit the file:**

```bash
nano ubuntu-22.04-lts.pkr.hcl

# Update the locals block:
# pm_node = "your-node-name"
# disk_store = "local-lvm"  # or local-zfs
# etc.
```

### 3. Create Password File

```bash
# Create password file (will be in .gitignore)
echo "your-proxmox-root-password" > pm_password.txt

# Secure it
chmod 600 pm_password.txt
```

### 4. Validate Packer Template

```bash
packer validate -var "pm_password=$(cat pm_password.txt)" ubuntu-22.04-lts.pkr.hcl
```

**Expected output:**
```
The configuration is valid.
```

**If you see errors:**
- Check syntax errors
- Verify Proxmox connectivity: `ping 192.168.1.200`
- Check API URL is accessible: `curl -k https://192.168.1.200:8006`

### 5. Build the Template

```bash
# Start the build (takes ~20-30 minutes)
packer build -var "pm_password=$(cat pm_password.txt)" ubuntu-22.04-lts.pkr.hcl
```

**What happens during build:**
1. Packer creates a temporary VM in Proxmox
2. Downloads Ubuntu ISO (if not cached)
3. Boots VM and triggers automated installation
4. SSHs into VM and runs provisioners
5. Converts VM to a template
6. Cleans up temporary VM

**Monitor progress:**
- Watch Packer output in terminal
- Or open Proxmox Web UI → your node → Virtual Machines
- You'll see `tmp-ubuntu-2204-ci` during build

**Expected output (final lines):**
```
==> proxmox-iso.ubuntu: Stopping VM
==> proxmox-iso.ubuntu: Converting VM to template
Build 'ubuntu-2204-cloudinit-template' finished after XX minutes XX seconds.

==> Wait completed after XX minutes XX seconds

==> Builds finished. The artifacts of successful builds are:
--> proxmox-iso.ubuntu: A template was created: ubuntu-2204-cloudinit-template
```

### 6. Verify Template in Proxmox

**Via Web UI:**
1. Navigate to your Proxmox node
2. Look for `ubuntu-2204-cloudinit-template` in the VM list
3. It should have a "Template" badge

**Via SSH:**
```bash
ssh root@192.168.1.200 "qm list | grep template"
```

### 7. Clean Up

```bash
# Remove password file
rm pm_password.txt

# Or keep it for future rebuilds (it's gitignored)
```

---

## Phase 2: Provision Infrastructure with Terraform

### 1. Navigate to Terraform Directory

```bash
cd ~/homelab.automation/terraform
```

### 2. Create Configuration File

```bash
# Copy example to actual config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Fill in these values:**

```hcl
# Proxmox API Configuration
proxmox_api_url          = "https://192.168.1.200:8006/api2/json"
proxmox_api_token_id     = "root@pam!terraform"
proxmox_api_token_secret = "your-secret-from-step-2-of-proxmox-config"
proxmox_tls_insecure     = true

# Infrastructure Settings
proxmox_node    = "duality"  # or your node name
proxmox_storage = "local-zfs"  # or local-lvm
template_name   = "ubuntu-2204-cloudinit-template"

# SSH Configuration (paste your public key from earlier)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... your-key-here"
ssh_user       = "admin"

# Network Settings
network_bridge  = "vmbr0"
network_gateway = "192.168.1.1"
dns_server      = "192.168.1.1"  # Change to 192.168.1.210 after Pi-hole
```

**To get your SSH public key again:**
```bash
cat ~/.ssh/id_rsa.pub
```

### 3. Initialize Terraform

```bash
# Download Proxmox provider
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding telmate/proxmox versions matching "~> 2.9.14"...
- Installing telmate/proxmox v2.9.14...

Terraform has been successfully initialized!
```

### 4. Test with a Simple VM

**Create test VM configuration:**

```bash
# Copy example
cp vms/vm-test.tf.example vms/vm-test.tf

# Edit if needed (already configured correctly)
nano vms/vm-test.tf
```

**Uncomment the module block:**

```bash
# Remove the # characters from the entire file
sed -i 's/^# //' vms/vm-test.tf
```

### 5. Plan the Deployment

```bash
terraform plan
```

**Expected output:**
```
Terraform will perform the following actions:

  # module.test_vm.proxmox_vm_qemu.vm will be created
  + resource "proxmox_vm_qemu" "vm" {
      + name   = "test-vm"
      + cores  = 1
      + memory = 1024
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**If you see errors:**
- Check API credentials in `terraform.tfvars`
- Verify template exists: `ssh root@192.168.1.200 "qm list | grep template"`
- Check network connectivity to Proxmox

### 6. Deploy Test VM

```bash
terraform apply

# Review the plan
# Type 'yes' when prompted
```

**Deployment takes 2-5 minutes:**
- Terraform clones the template
- Cloud-init configures the VM
- QEMU guest agent starts

**Expected output:**
```
module.test_vm.proxmox_vm_qemu.vm: Creating...
module.test_vm.proxmox_vm_qemu.vm: Still creating... [10s elapsed]
module.test_vm.proxmox_vm_qemu.vm: Creation complete after 2m15s [id=...]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

test_vm_ip = "192.168.1.230"
```

### 7. Verify VM is Running

**Via Proxmox Web UI:**
1. Navigate to your node → Virtual Machines
2. Look for `test-vm`
3. Should show "running" status

**Via SSH:**
```bash
# Wait 2-3 minutes for cloud-init to complete
sleep 180

# Test SSH access
ssh admin@192.168.1.230

# Should connect without password
# Exit
exit
```

### 8. Destroy Test VM (Optional)

```bash
# Clean up
terraform destroy

# Type 'yes' when prompted
```

**Or keep it running for Ansible testing in Phase 3.**

---

## Phase 3: Configure Services with Ansible

### 1. Navigate to Ansible Directory

```bash
cd ~/homelab.automation/ansible
```

### 2. Set Up Vault Password

```bash
# Create vault password file
echo "your-strong-vault-password" > vault_password.txt

# Secure it
chmod 600 vault_password.txt
```

### 3. Create Encrypted Vault

```bash
# Create vault for secrets
ansible-vault create group_vars/vault.yml
```

**Editor will open. Add your secrets:**

```yaml
---
# Proxmox credentials
vault_proxmox_api_token: "your-api-token-secret"

# Service passwords (add as needed)
vault_gitea_admin_password: "strong-password-here"
vault_semaphore_admin_password: "strong-password-here"

# Save and exit (Ctrl+X, Y, Enter in nano)
```

### 4. Update Inventory

**Edit inventory to include test VM:**

```bash
nano inventory/hosts.yml
```

**Uncomment test VM section:**

```yaml
all:
  children:
    # Test VMs
    test:
      hosts:
        test-vm:
          ansible_host: 192.168.1.230

  vars:
    ansible_user: admin
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_python_interpreter: /usr/bin/python3
```

### 5. Test Ansible Connectivity

```bash
# Ping all hosts
ansible all -m ping

# Expected output:
# test-vm | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

**If connection fails:**
```bash
# Try manual SSH first
ssh admin@192.168.1.230

# Check cloud-init finished
ssh admin@192.168.1.230 "cloud-init status"
# Should show: status: done
```

### 6. Run Playbook (Dry Run)

```bash
# Check what would be changed
ansible-playbook playbooks/site.yml --check
```

### 7. Run Playbook

```bash
# Apply configuration
ansible-playbook playbooks/site.yml
```

**What this does:**
1. Updates all packages
2. Installs common utilities
3. Configures SSH (disables root, password auth)
4. Sets timezone
5. Enables automatic security updates
6. Installs Docker (if host is in automation/infrastructure groups)

**Expected output (final):**
```
PLAY RECAP *******************************************************************
test-vm                    : ok=15   changed=8    unreachable=0    failed=0
```

### 8. Verify Configuration

```bash
# SSH into VM
ssh admin@192.168.1.230

# Check Docker is installed (if applicable)
docker --version

# Check timezone
timedatectl

# Check common packages
htop --version
tmux -V

# Exit
exit
```

---

## Troubleshooting

### Packer Issues

**Error: "Failed to connect to SSH"**
```bash
# Check VM console in Proxmox Web UI
# Cloud-init might have failed

# Verify user-data file is correct
cat packer/http/user-data

# Rebuild with debug:
export PACKER_LOG=1
packer build -var "pm_password=$(cat pm_password.txt)" ubuntu-22.04-lts.pkr.hcl
```

**Error: "ISO not found"**
```bash
# Verify ISO storage pool
ssh root@192.168.1.200 "pvesm status"

# Check if ISO downloaded
ssh root@192.168.1.200 "ls -lh /var/lib/vz/template/iso/"
```

**Error: "Disk storage not found"**
```bash
# List storage pools
ssh root@192.168.1.200 "pvesm status"

# Update packer config with correct storage name
nano packer/ubuntu-22.04-lts.pkr.hcl
# Change disk_store = "local-lvm" (or whatever you have)
```

### Terraform Issues

**Error: "401 Unauthorized"**
```bash
# API token is wrong or expired
# Recreate in Proxmox: Datacenter → Permissions → API Tokens
# Update terraform.tfvars

# Test API manually:
curl -k -H "Authorization: PVEAPIToken=root@pam!terraform=YOUR-SECRET" \
  https://192.168.1.200:8006/api2/json/nodes
```

**Error: "Template not found"**
```bash
# Verify template exists
ssh root@192.168.1.200 "qm list | grep template"

# Check name matches terraform.tfvars
grep template_name terraform.tfvars
```

**Error: "IP address conflict"**
```bash
# VM won't start or network doesn't work
# Change IP in vms/vm-test.tf
nano vms/vm-test.tf
# ip_address = "192.168.1.231"  # Use a different IP

# Destroy and recreate
terraform destroy
terraform apply
```

### Ansible Issues

**Error: "Host unreachable"**
```bash
# Test network connectivity
ping 192.168.1.230

# Test SSH manually
ssh admin@192.168.1.230

# Check cloud-init completed
ssh admin@192.168.1.230 "cloud-init status --wait"
```

**Error: "Permission denied"**
```bash
# SSH key not accepted
# Verify key is in VM
ssh admin@192.168.1.230 "cat ~/.ssh/authorized_keys"

# Should contain your public key
# If not, manually add it:
ssh-copy-id admin@192.168.1.230
```

**Error: "Vault password file not found"**
```bash
# Create it
echo "your-password" > ansible/vault_password.txt
chmod 600 ansible/vault_password.txt

# Or use flag
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### WSL2 Issues

**WSL2 can't reach Proxmox**
```bash
# From WSL2, test connectivity
ping 192.168.1.200

# If fails, check Windows firewall
# From PowerShell (as Admin):
Get-NetConnectionProfile
# Set to Private if currently Public:
Set-NetConnectionProfile -InterfaceAlias "Wi-Fi" -NetworkCategory Private
```

**SSH keys not working from WSL2**
```bash
# Check permissions on SSH key
ls -la ~/.ssh/
# id_rsa should be 600

# Fix if needed
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

**"command not found" errors**
```bash
# Verify tools installed in WSL2, not Windows
which terraform packer ansible
# Should show /usr/bin/... paths

# If not found, reinstall in WSL2
```

---

## Quick Reference

### Daily Workflow

**Start WSL2:**
```bash
wsl
cd ~/homelab.automation
```

**Build new template:**
```bash
cd packer
echo "password" > pm_password.txt
packer build -var "pm_password=$(cat pm_password.txt)" ubuntu-22.04-lts.pkr.hcl
rm pm_password.txt
```

**Deploy VMs:**
```bash
cd ../terraform
terraform plan
terraform apply
```

**Configure VMs:**
```bash
cd ../ansible
ansible-playbook playbooks/site.yml
```

### Important File Locations

**In WSL2:**
```
~/homelab.automation/          - Main repository
~/.ssh/id_rsa                  - SSH private key
~/homelab.automation/terraform/terraform.tfvars  - Terraform secrets
~/homelab.automation/ansible/vault_password.txt  - Ansible vault password
```

**In Proxmox:**
```
/var/lib/vz/template/iso/      - ISO images
/var/lib/vz/template/qemu/     - VM templates
```

### Common Commands

**Packer:**
```bash
packer validate <file>         - Validate template
packer build <file>            - Build template
```

**Terraform:**
```bash
terraform init                 - Initialize providers
terraform validate             - Validate syntax
terraform plan                 - Preview changes
terraform apply                - Apply changes
terraform destroy              - Destroy resources
terraform state list           - List managed resources
```

**Ansible:**
```bash
ansible all -m ping            - Test connectivity
ansible-playbook <playbook>    - Run playbook
ansible-playbook <playbook> --check  - Dry run
ansible-playbook <playbook> --limit test  - Run on specific group
ansible-vault edit vault.yml   - Edit encrypted vault
```

### IP Address Allocations

**From ARCHITECTURE.md:**
```
192.168.1.200     - Proxmox host
192.168.1.210     - Pi-hole/DNS
192.168.1.211     - Traefik proxy
192.168.1.212     - Gitea
192.168.1.213     - Semaphore
192.168.1.220     - NAS
192.168.1.230-239 - Test/Dev VMs
```

### Emergency Recovery

**Can't connect to Proxmox:**
1. Verify network: `ping 192.168.1.200`
2. Check Proxmox is running (physical access or IPMI)
3. Try HTTPS: Open browser to `https://192.168.1.200:8006`

**Terraform state corrupted:**
```bash
# Backup state
cp terraform.tfstate terraform.tfstate.backup

# Import existing resources
terraform import module.test_vm.proxmox_vm_qemu.vm <vm-id>

# Or start fresh (destroys VMs)
rm terraform.tfstate*
terraform init
```

**Ansible can't connect to VMs:**
```bash
# Check SSH from Windows/WSL2
ssh admin@<vm-ip>

# Regenerate host keys
ssh-keygen -R <vm-ip>

# Force password auth (to fix SSH keys)
ansible all -m ping --ask-pass
```

---

## Next Steps After Phase 0

Once you've successfully:
- ✅ Built the Packer template
- ✅ Deployed a test VM with Terraform
- ✅ Configured the test VM with Ansible

**You're ready for Phase 1:**

1. **Deploy Gitea** (self-hosted Git)
2. **Deploy Semaphore** (Ansible/Terraform UI)
3. **Migrate code to Gitea**
4. **Run future deployments through Semaphore**

See [SERVICE_CATALOG.md](../SERVICE_CATALOG.md) for the full roadmap.

---

## Support & Documentation

**Main docs:**
- [README.md](../README.md) - Project overview
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Network and architecture
- [SERVICE_CATALOG.md](../SERVICE_CATALOG.md) - Service inventory

**External resources:**
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Packer Proxmox Builder](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [WSL2 Documentation](https://learn.microsoft.com/en-us/windows/wsl/)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-14
**Target Platform:** Windows 11 with WSL2 → Proxmox VE 8.x
