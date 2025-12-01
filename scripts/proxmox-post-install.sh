#!/bin/bash
#
# Proxmox VE Post-Installation Script
# Automates common post-install tasks
#
# Usage: ./proxmox-post-install.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

echo ""
log_info "=========================================="
log_info "Proxmox VE Post-Installation Setup"
log_info "=========================================="
echo ""

# ============================================================================
# Step 1: Remove subscription notice
# ============================================================================
log_step "Step 1: Removing 'No valid subscription' notice"

if [[ -f /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]]; then
    # Backup original
    if [[ ! -f /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak ]]; then
        cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js \
           /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
        log_info "Original file backed up"
    fi

    # Remove subscription notice
    sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" \
        /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

    # Restart web service
    systemctl restart pveproxy.service

    log_info "✓ Subscription notice removed (refresh browser)"
else
    log_warn "Proxmox library file not found - skipping"
fi

echo ""

# ============================================================================
# Step 2: Update system
# ============================================================================
log_step "Step 2: Updating Proxmox system"

read -p "Do you want to update all packages now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Updating package lists..."
    apt-get update

    log_info "Upgrading packages (this may take several minutes)..."
    apt-get full-upgrade -y

    log_info "✓ System updated"

    # Check if reboot is required
    if [[ -f /var/run/reboot-required ]]; then
        log_warn "A reboot is required to complete the update"
        read -p "Do you want to reboot now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Rebooting in 10 seconds... (Ctrl+C to cancel)"
            sleep 10
            reboot
        fi
    fi
else
    log_info "Skipping system update"
fi

echo ""

# ============================================================================
# Step 3: Install useful packages
# ============================================================================
log_step "Step 3: Installing useful utilities"

PACKAGES=(
    vim
    tmux
    htop
    iotop
    iftop
    ncdu
    tree
    git
    curl
    wget
    net-tools
    dnsutils
    smartmontools
    lm-sensors
)

log_info "Installing: ${PACKAGES[*]}"
apt-get install -y "${PACKAGES[@]}"

log_info "✓ Utilities installed"

echo ""

# ============================================================================
# Step 4: Configure PVE repository (disable enterprise, enable no-subscription)
# ============================================================================
log_step "Step 4: Configuring APT repositories"

read -p "Switch to no-subscription repository? (recommended for home use) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Disable enterprise repo
    if [[ -f /etc/apt/sources.list.d/pve-enterprise.list ]]; then
        mv /etc/apt/sources.list.d/pve-enterprise.list \
           /etc/apt/sources.list.d/pve-enterprise.list.disabled
        log_info "✓ Enterprise repository disabled"
    fi

    # Enable no-subscription repo
    if ! grep -q "pve-no-subscription" /etc/apt/sources.list; then
        echo "" >> /etc/apt/sources.list
        echo "# PVE pve-no-subscription repository" >> /etc/apt/sources.list
        echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list
        log_info "✓ No-subscription repository enabled"
    else
        log_info "No-subscription repository already configured"
    fi

    # Update package lists
    apt-get update
else
    log_info "Skipping repository configuration"
fi

echo ""

# ============================================================================
# Step 5: Enable IOMMU (for GPU/USB passthrough)
# ============================================================================
log_step "Step 5: IOMMU configuration for device passthrough"

read -p "Enable IOMMU for GPU/USB passthrough? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Detect CPU vendor
    if grep -q "Intel" /proc/cpuinfo; then
        IOMMU_PARAM="intel_iommu=on"
        log_info "Intel CPU detected"
    elif grep -q "AMD" /proc/cpuinfo; then
        IOMMU_PARAM="amd_iommu=on"
        log_info "AMD CPU detected"
    else
        log_warn "Could not detect CPU vendor"
        IOMMU_PARAM="intel_iommu=on"
    fi

    # Update GRUB
    if ! grep -q "$IOMMU_PARAM" /etc/default/grub; then
        sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet $IOMMU_PARAM\"/" /etc/default/grub
        update-grub
        log_info "✓ IOMMU enabled (requires reboot)"
    else
        log_info "IOMMU already enabled"
    fi

    # Load VFIO modules
    if ! grep -q "vfio" /etc/modules; then
        cat >> /etc/modules <<EOF
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF
        log_info "✓ VFIO modules configured (requires reboot)"
    fi
else
    log_info "Skipping IOMMU configuration"
fi

echo ""

# ============================================================================
# Step 6: Create API token for Terraform
# ============================================================================
log_step "Step 6: Create Proxmox API token for Terraform"

read -p "Create API token for Terraform? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Creating API token 'terraform' for user 'root@pam'..."

    # Check if token already exists
    if pveum user token list root@pam | grep -q "terraform"; then
        log_warn "Token 'terraform' already exists"
        read -p "Delete and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pveum user token remove root@pam terraform
            log_info "Old token deleted"
        else
            log_info "Skipping token creation"
            SKIP_TOKEN=true
        fi
    fi

    if [[ "${SKIP_TOKEN:-false}" != "true" ]]; then
        # Create token
        echo ""
        log_info "Creating API token..."
        pveum user token add root@pam terraform --privsep 0

        echo ""
        log_warn "IMPORTANT: Copy the 'value' field above!"
        log_warn "You will need this for terraform/terraform.tfvars"
        log_warn "It will not be displayed again!"
        echo ""
        read -p "Press Enter when you've copied the token..."
    fi
else
    log_info "Skipping API token creation"
fi

echo ""

# ============================================================================
# Step 7: SSH key generation
# ============================================================================
log_step "Step 7: SSH key setup"

if [[ -f /root/.ssh/id_rsa ]]; then
    log_info "SSH key already exists at /root/.ssh/id_rsa"
    cat /root/.ssh/id_rsa.pub
    echo ""
    log_info "Copy the public key above for terraform/terraform.tfvars"
else
    read -p "Generate SSH key pair? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh-keygen -t rsa -b 4096 -C "homelab-automation" -f /root/.ssh/id_rsa -N ""
        log_info "✓ SSH key generated"
        echo ""
        log_info "Public key:"
        cat /root/.ssh/id_rsa.pub
        echo ""
    else
        log_info "Skipping SSH key generation"
    fi
fi

echo ""

# ============================================================================
# Step 8: Email configuration (optional)
# ============================================================================
log_step "Step 8: Email notifications (optional)"

read -p "Configure email notifications via Gmail? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Install postfix
    log_info "Installing postfix..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y postfix libsasl2-modules

    # Configure Gmail relay
    read -p "Enter your Gmail address: " GMAIL_USER
    read -sp "Enter your Gmail App Password: " GMAIL_PASS
    echo ""

    cat >> /etc/postfix/main.cf <<EOF

# Gmail relay configuration
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
EOF

    # Add credentials
    cat > /etc/postfix/sasl_passwd <<EOF
[smtp.gmail.com]:587    $GMAIL_USER:$GMAIL_PASS
EOF

    # Secure and hash
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd

    # Restart postfix
    systemctl restart postfix

    log_info "✓ Email configured"

    # Test email
    read -p "Send test email to $GMAIL_USER? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Test email from Proxmox" | mail -s "Proxmox Test" "$GMAIL_USER"
        log_info "Test email sent - check your inbox"
    fi
else
    log_info "Skipping email configuration"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
log_info "=========================================="
log_info "Post-Installation Setup Complete!"
log_info "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. If you enabled IOMMU, reboot now:"
echo "   reboot"
echo ""
echo "2. Install automation tools:"
echo "   cd /root"
echo "   git clone https://github.com/yourusername/-homelab.automation.git"
echo "   cd -homelab.automation"
echo "   chmod +x scripts/install-tools.sh"
echo "   ./scripts/install-tools.sh"
echo ""
echo "3. Follow the Proxmox Install Guide:"
echo "   docs/PROXMOX_INSTALL_GUIDE.md"
echo ""
log_info "Done! 🎉"
