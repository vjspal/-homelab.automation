# Proxmox VE 9.1 Fresh Installation Guide

**Complete guide for installing Proxmox VE 9.1 with network configuration, ZFS pools, and automation tools.**

---

## 📋 Pre-Installation Checklist

### Hardware Requirements
- [ ] CPU: Intel Xeon or equivalent (virtualization support required)
- [ ] RAM: Minimum 8 GB (32 GB recommended)
- [ ] Storage:
  - Boot disk (SSD recommended, minimum 32 GB)
  - Data disk(s) for ZFS pool (HDD/SSD 1 TB+)
- [ ] Network: Ethernet connection with internet access

### Information to Prepare
- [ ] **Static IP address** for Proxmox host (e.g., 192.168.1.200)
- [ ] **Subnet mask** (e.g., 255.255.255.0 or /24)
- [ ] **Gateway IP** (your router, e.g., 192.168.1.1)
- [ ] **DNS servers** (e.g., 1.1.1.1, 8.8.8.8)
- [ ] **Hostname** (e.g., pve or duality)
- [ ] **Domain name** (e.g., homelab.local)
- [ ] **Root password** (strong password for Proxmox)
- [ ] **Email address** (for system notifications)

### Installation Media
- [ ] Proxmox VE 9.1 ISO downloaded from https://www.proxmox.com/en/downloads
- [ ] USB drive (minimum 2 GB) prepared with:
  - **Linux/Mac**: `dd if=proxmox-ve_*.iso of=/dev/sdX bs=1M status=progress`
  - **Windows**: Use Rufus or Balena Etcher

---

## 🔧 Part 1: Proxmox VE Installation

### Step 1: Boot from USB

1. Insert USB drive and boot from it (press F12/F11/Delete for boot menu)
2. Select **Install Proxmox VE (Graphical)**
3. Accept the EULA

### Step 2: Target Disk Selection

**For ZFS Setup:**
1. Click on **Options**
2. Select filesystem: **ZFS (RAID0)** for single disk or **ZFS (RAID1/RAID10)** for multiple disks
3. Select target disk(s) for Proxmox OS installation
4. **Important**: Leave your large data disks unselected (we'll configure them later)

**ZFS Options:**
- **ashift**: 12 (for 4K sector disks, default is good)
- **compress**: lz4 (recommended for performance)
- **checksum**: on (data integrity)
- **copies**: 1 (default)

Click **Next**

### Step 3: Location and Time Zone

1. Select your **Country**
2. Select your **Time zone**
3. Select your **Keyboard Layout**

Click **Next**

### Step 4: Administration Password and Email

1. **Password**: Enter a strong root password
2. **Confirm Password**: Re-enter password
3. **Email**: Enter your email for system notifications

Click **Next**

### Step 5: Network Configuration

**CRITICAL - Use Static IP:**

1. **Management Interface**: Select your primary network interface (usually `enp*` or `eno1`)
2. **Hostname (FQDN)**: `pve.homelab.local` or `duality.homelab.local`
3. **IP Address (CIDR)**: `192.168.1.200/24`
4. **Gateway**: `192.168.1.1`
5. **DNS Server**: `1.1.1.1` (or your preferred DNS)

**Example Configuration:**
```
Hostname (FQDN):  pve.homelab.local
IP Address (CIDR): 192.168.1.200/24
Gateway:          192.168.1.1
DNS Server:       1.1.1.1
```

Click **Next**

### Step 6: Review and Install

1. Review all settings carefully
2. Click **Install**
3. Wait 5-15 minutes for installation to complete
4. Remove USB drive when prompted
5. Reboot

---

## 🌐 Part 2: Post-Installation - Initial Setup

### Step 1: Access Web Interface

1. From another computer on the same network, open browser
2. Navigate to: `https://192.168.1.200:8006`
3. Accept the self-signed certificate warning (click Advanced → Proceed)
4. Login with:
   - **User**: `root`
   - **Realm**: `Linux PAM standard authentication`
   - **Password**: Your root password

### Step 2: Remove "No Valid Subscription" Message

```bash
# SSH to Proxmox (or use Shell in web UI)
ssh root@192.168.1.200

# Edit the subscription notice script
sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" \
  /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# Restart web service
systemctl restart pveproxy.service
```

Refresh browser - no more subscription nag!

### Step 3: Update Proxmox

```bash
# Update package lists
apt update

# Upgrade all packages
apt full-upgrade -y

# Reboot to load new kernel (if kernel was updated)
reboot
```

### Step 4: Configure Email Notifications (Optional)

**If using Gmail:**

```bash
# Install postfix
apt install -y postfix libsasl2-modules

# Configure Gmail relay
cat >> /etc/postfix/main.cf <<EOF
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
EOF

# Add Gmail credentials
cat > /etc/postfix/sasl_passwd <<EOF
[smtp.gmail.com]:587    your-email@gmail.com:your-app-password
EOF

# Secure and hash the password file
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

# Restart postfix
systemctl restart postfix

# Test email
echo "Test from Proxmox" | mail -s "Proxmox Test" your-email@gmail.com
```

**For Gmail App Password:**
1. Go to Google Account → Security
2. Enable 2-Factor Authentication
3. Create App Password for "Mail"
4. Use that password in `/etc/postfix/sasl_passwd`

---

## 💾 Part 3: ZFS Storage Pool Setup

### Option A: Single Large Disk for VM Storage

```bash
# List available disks
lsblk

# Create ZFS pool on /dev/sdb (adjust to your disk)
zpool create -f \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O relatime=on \
  -O normalization=formD \
  -O xattr=sa \
  -m /mnt/vm-storage \
  vm-storage /dev/sdb

# Verify pool
zpool status

# Add to Proxmox storage
pvesm add zfspool vm-storage --pool vm-storage --content rootdir,images
```

### Option B: Mirrored Pool (2+ Disks)

```bash
# Create mirrored pool (RAID1)
zpool create -f \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  vm-storage mirror /dev/sdb /dev/sdc

# Or RAID10 (4 disks)
zpool create -f \
  -o ashift=12 \
  -O compression=lz4 \
  vm-storage mirror /dev/sdb /dev/sdc mirror /dev/sdd /dev/sde
```

### ZFS Best Practices

```bash
# Enable automatic snapshots (optional)
apt install -y zfs-auto-snapshot

# Set scrub schedule (monthly)
cat > /etc/cron.d/zfspool-scrub <<'EOF'
# Monthly ZFS scrub on first Sunday at 2 AM
0 2 * * 0 [ $(date +\%d) -le 7 ] && root /sbin/zpool scrub vm-storage
EOF

# Check pool health
zpool status
zfs list
```

---

## 🌐 Part 4: Network Configuration with VLANs

**See `docs/NETWORK_SETUP.md` for complete VLAN configuration.**

### Quick VLAN Setup (Advanced)

Edit `/etc/network/interfaces`:

```bash
# Management Network (No VLAN)
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.200/24
    gateway 192.168.1.1
    bridge-ports enp0s31f6
    bridge-stp off
    bridge-fd 0

# VLAN 10 - Services Network
auto vmbr0.10
iface vmbr0.10 inet manual
    vlan-raw-device vmbr0

auto vmbr10
iface vmbr10 inet static
    address 192.168.10.1/24
    bridge-ports vmbr0.10
    bridge-stp off
    bridge-fd 0

# VLAN 20 - IoT/Cameras Network
auto vmbr0.20
iface vmbr0.20 inet manual
    vlan-raw-device vmbr0

auto vmbr20
iface vmbr20 inet static
    address 192.168.20.1/24
    bridge-ports vmbr0.20
    bridge-stp off
    bridge-fd 0
```

Apply changes:
```bash
ifreload -a
```

---

## 🛠️ Part 5: Install Automation Tools

**Automated installation script available at `scripts/install-tools.sh`**

```bash
# Clone your repository
cd /root
git clone https://github.com/yourusername/-homelab.automation.git
cd -homelab.automation

# Run tool installation script
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh
```

**Manual Installation (if preferred):**

### Install Packer

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  tee /etc/apt/sources.list.d/hashicorp.list

# Install Packer
apt update
apt install -y packer

# Verify
packer version
```

### Install Terraform

```bash
# Install from same HashiCorp repo
apt install -y terraform

# Verify
terraform version
```

### Install Ansible

```bash
# Install dependencies
apt install -y python3-pip python3-venv

# Install Ansible via pip
pip3 install ansible --break-system-packages

# Or using venv (recommended)
python3 -m venv /opt/ansible-venv
source /opt/ansible-venv/bin/activate
pip install ansible

# Make permanent
echo 'export PATH=/opt/ansible-venv/bin:$PATH' >> /root/.bashrc

# Verify
ansible --version
```

---

## 🔐 Part 6: Security Hardening

### Create API Token for Terraform

```bash
# Create API token (save the secret - it's only shown once!)
pveum user token add root@pam terraform --privsep 0

# Output will be:
# ┌──────────────┬──────────────────────────────────────┐
# │ key          │ value                                │
# ╞══════════════╪══════════════════════════════════════╡
# │ full-tokenid │ root@pam!terraform                   │
# ├──────────────┼──────────────────────────────────────┤
# │ info         │ {"privsep":0}                        │
# ├──────────────┼──────────────────────────────────────┤
# │ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
# └──────────────┴──────────────────────────────────────┘

# Copy the 'value' field - you'll need it for terraform.tfvars
```

### SSH Key Setup

```bash
# Generate SSH key pair (if not already existing)
ssh-keygen -t rsa -b 4096 -C "homelab-automation" -f /root/.ssh/id_rsa -N ""

# Display public key (you'll need this for terraform.tfvars)
cat /root/.ssh/id_rsa.pub
```

### Firewall Configuration

```bash
# Enable Proxmox firewall
pvesh set /cluster/firewall/options --enable 1

# Or via Web UI:
# Datacenter → Firewall → Options → Enable: Yes
```

---

## 📝 Part 7: Configuration Files Setup

### Create terraform.tfvars

```bash
cd /root/-homelab.automation/terraform

# Copy example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Fill in:**
```hcl
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # From pveum command
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."  # From /root/.ssh/id_rsa.pub
```

### Create Ansible Vault

```bash
cd /root/-homelab.automation/ansible

# Generate vault password
openssl rand -base64 32 > vault_password.txt
chmod 600 vault_password.txt

# Create encrypted vault
ansible-vault create group_vars/vault.yml
# Enter password from vault_password.txt

# Add sample secrets:
---
vault_mysql_root_password: "changeme"
vault_nextcloud_admin_password: "changeme"
vault_gitea_admin_password: "changeme"
```

---

## ✅ Post-Installation Validation

### System Checks

```bash
# Check Proxmox version
pveversion

# Check ZFS pool
zpool status

# Check network configuration
ip addr show
ip route

# Check DNS resolution
nslookup google.com

# Verify tools
packer version
terraform version
ansible --version
```

### Test VM Template Build

```bash
cd /root/-homelab.automation/packer

# Validate Packer template
packer validate -var "pm_password=$(read -sp 'Password: ' pwd; echo $pwd)" ubuntu-22.04-lts.pkr.hcl

# Build template (takes 20-30 minutes)
read -sp 'Proxmox Password: ' PM_PASSWORD
packer build -var "pm_password=$PM_PASSWORD" ubuntu-22.04-lts.pkr.hcl
```

---

## 🚀 Next Steps

1. **Build Packer Template** (30 min)
   ```bash
   cd /root/-homelab.automation/packer
   packer build -var "pm_password=YOUR_PASSWORD" ubuntu-22.04-lts.pkr.hcl
   ```

2. **Deploy Test VM** (5 min)
   ```bash
   cd /root/-homelab.automation/terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Configure with Ansible** (5 min)
   ```bash
   cd /root/-homelab.automation/ansible
   ansible all -m ping
   ansible-playbook playbooks/site.yml
   ```

4. **Proceed to Phase 1** - Deploy Gitea, Semaphore, and validate full workflow

---

## 🆘 Troubleshooting

### Web UI Not Accessible
- Check IP address: `ip addr show`
- Check firewall: `iptables -L`
- Restart web service: `systemctl restart pveproxy`

### ZFS Pool Issues
- Check status: `zpool status -v`
- Check disk health: `smartctl -a /dev/sdX`
- Scrub pool: `zpool scrub vm-storage`

### Email Not Working
- Check postfix: `systemctl status postfix`
- Check logs: `tail -f /var/log/mail.log`
- Test: `echo "test" | mail -s "test" you@example.com`

### Tool Installation Failed
- Check internet: `ping -c 3 google.com`
- Update repos: `apt update`
- Check logs: `journalctl -xe`

---

## 📚 Additional Resources

- **Proxmox VE Documentation**: https://pve.proxmox.com/pve-docs/
- **ZFS Documentation**: https://openzfs.github.io/openzfs-docs/
- **Network Setup Guide**: `docs/NETWORK_SETUP.md`
- **Service Deployment**: `docs/SERVICE_DEPLOYMENT.md`

---

**Installation Guide Version**: 1.0
**Last Updated**: 2025-12-01
**Proxmox VE Version**: 9.1
**Author**: Automated Homelab Project
