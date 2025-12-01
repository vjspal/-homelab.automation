#!/bin/bash
#
# Automated Installation Script for Homelab Automation Tools
# Installs: Packer, Terraform, Ansible
# Platform: Proxmox VE 9.x (Debian-based)
#
# Usage: ./install-tools.sh
#

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "=========================================="
log_info "Homelab Automation Tools Installation"
log_info "=========================================="
echo ""

# Update system
log_info "Updating package lists..."
apt-get update -qq

log_info "Installing prerequisites..."
apt-get install -y -qq \
    wget \
    curl \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    git \
    jq \
    unzip

echo ""
log_info "==================== PACKER ===================="

# Check if Packer is already installed
if command -v packer &> /dev/null; then
    PACKER_VERSION=$(packer version | head -n1 | awk '{print $2}')
    log_warn "Packer is already installed: $PACKER_VERSION"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Packer installation"
    else
        INSTALL_PACKER=true
    fi
else
    INSTALL_PACKER=true
fi

if [[ "${INSTALL_PACKER:-false}" == "true" ]]; then
    log_info "Adding HashiCorp GPG key..."
    wget -q -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    log_info "Adding HashiCorp repository..."
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    log_info "Installing Packer..."
    apt-get update -qq
    apt-get install -y packer

    PACKER_VERSION=$(packer version | head -n1)
    log_info "✓ Packer installed: $PACKER_VERSION"
fi

echo ""
log_info "==================== TERRAFORM ===================="

# Check if Terraform is already installed
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_warn "Terraform is already installed: v$TERRAFORM_VERSION"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Terraform installation"
    else
        INSTALL_TERRAFORM=true
    fi
else
    INSTALL_TERRAFORM=true
fi

if [[ "${INSTALL_TERRAFORM:-false}" == "true" ]]; then
    log_info "Installing Terraform (from HashiCorp repository)..."
    apt-get install -y terraform

    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "✓ Terraform installed: v$TERRAFORM_VERSION"
fi

echo ""
log_info "==================== ANSIBLE ===================="

# Check if Ansible is already installed
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | awk '{print $3}')
    log_warn "Ansible is already installed: $ANSIBLE_VERSION"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Ansible installation"
    else
        INSTALL_ANSIBLE=true
    fi
else
    INSTALL_ANSIBLE=true
fi

if [[ "${INSTALL_ANSIBLE:-false}" == "true" ]]; then
    log_info "Installing Python3 and pip..."
    apt-get install -y python3 python3-pip python3-venv

    log_info "Creating Python virtual environment for Ansible..."
    VENV_PATH="/opt/ansible-venv"

    if [[ -d "$VENV_PATH" ]]; then
        log_warn "Virtual environment already exists at $VENV_PATH"
        rm -rf "$VENV_PATH"
    fi

    python3 -m venv "$VENV_PATH"

    log_info "Installing Ansible in virtual environment..."
    "$VENV_PATH/bin/pip" install --quiet --upgrade pip
    "$VENV_PATH/bin/pip" install --quiet ansible

    # Add to PATH in bashrc if not already there
    if ! grep -q "/opt/ansible-venv/bin" /root/.bashrc; then
        log_info "Adding Ansible to PATH in /root/.bashrc..."
        echo '' >> /root/.bashrc
        echo '# Ansible virtual environment' >> /root/.bashrc
        echo 'export PATH="/opt/ansible-venv/bin:$PATH"' >> /root/.bashrc
    fi

    # Create symlinks for convenience
    log_info "Creating symlinks in /usr/local/bin..."
    ln -sf "$VENV_PATH/bin/ansible" /usr/local/bin/ansible
    ln -sf "$VENV_PATH/bin/ansible-playbook" /usr/local/bin/ansible-playbook
    ln -sf "$VENV_PATH/bin/ansible-vault" /usr/local/bin/ansible-vault
    ln -sf "$VENV_PATH/bin/ansible-galaxy" /usr/local/bin/ansible-galaxy

    ANSIBLE_VERSION=$("$VENV_PATH/bin/ansible" --version | head -n1 | awk '{print $3}')
    log_info "✓ Ansible installed: $ANSIBLE_VERSION"
    log_warn "Note: You may need to run 'source /root/.bashrc' or open a new shell"
fi

echo ""
log_info "==================== ADDITIONAL TOOLS ===================="

# Install useful utilities
log_info "Installing additional utilities..."
apt-get install -y -qq \
    vim \
    tmux \
    htop \
    ncdu \
    tree \
    net-tools \
    dnsutils \
    iotop \
    iftop

log_info "✓ Additional utilities installed"

echo ""
log_info "==================== VERIFICATION ===================="

# Verify installations
echo ""
log_info "Verifying installations..."
echo ""

# Packer
if command -v packer &> /dev/null; then
    PACKER_VER=$(packer version | head -n1)
    echo -e "${GREEN}✓ Packer:${NC} $PACKER_VER"
else
    echo -e "${RED}✗ Packer:${NC} Not found"
fi

# Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VER=$(terraform version -json | jq -r '.terraform_version')
    echo -e "${GREEN}✓ Terraform:${NC} v$TERRAFORM_VER"
else
    echo -e "${RED}✗ Terraform:${NC} Not found"
fi

# Ansible
if command -v ansible &> /dev/null; then
    ANSIBLE_VER=$(ansible --version | head -n1 | awk '{print $3}')
    echo -e "${GREEN}✓ Ansible:${NC} $ANSIBLE_VER"
else
    echo -e "${RED}✗ Ansible:${NC} Not found"
fi

echo ""
log_info "==================== NEXT STEPS ===================="
echo ""
echo "1. Create Proxmox API token:"
echo "   pveum user token add root@pam terraform --privsep 0"
echo ""
echo "2. Generate SSH key (if not exists):"
echo "   ssh-keygen -t rsa -b 4096 -C 'homelab-automation' -f ~/.ssh/id_rsa"
echo ""
echo "3. Configure Terraform variables:"
echo "   cd terraform/"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "   nano terraform.tfvars  # Add API token and SSH key"
echo ""
echo "4. Setup Ansible Vault:"
echo "   cd ansible/"
echo "   openssl rand -base64 32 > vault_password.txt"
echo "   chmod 600 vault_password.txt"
echo "   ansible-vault create group_vars/vault.yml"
echo ""
echo "5. Build Packer template:"
echo "   cd packer/"
echo "   packer build -var 'pm_password=YOUR_PASSWORD' ubuntu-22.04-lts.pkr.hcl"
echo ""
log_info "Installation complete! 🎉"
echo ""
