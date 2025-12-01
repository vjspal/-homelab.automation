# Network Architecture & VLAN Setup Guide

**Complete network design for single or multi-node Proxmox homelab with VLAN segmentation.**

---

## 🎯 Network Design Goals

1. **Segmentation**: Isolate different types of traffic (management, services, IoT)
2. **Security**: Prevent unauthorized access between network segments
3. **Scalability**: Support adding additional Proxmox nodes
4. **Flexibility**: Easy to add/remove VMs and services
5. **Performance**: Minimize bottlenecks and maximize throughput

---

## 📐 Network Architecture Overview

### Single-Node Setup (Starting Point)

```
Internet
    │
    ├─ Router (192.168.1.1)
    │   └─ DHCP: 192.168.1.100-199
    │
    └─ Proxmox Host (192.168.1.200)
        │
        ├─ vmbr0 (Management - No VLAN)
        │   └─ 192.168.1.0/24
        │
        ├─ vmbr10 (Services - VLAN 10)
        │   └─ 192.168.10.0/24
        │
        ├─ vmbr20 (IoT/Cameras - VLAN 20)
        │   └─ 192.168.20.0/24
        │
        └─ vmbr30 (Storage - VLAN 30) [Optional]
            └─ 192.168.30.0/24
```

### Multi-Node Setup (Future Expansion)

```
Internet
    │
    ├─ Router (192.168.1.1)
    │
    ├─ Managed Switch (VLAN-aware)
    │   ├─ VLAN 1 (Management)
    │   ├─ VLAN 10 (Services)
    │   ├─ VLAN 20 (IoT)
    │   └─ VLAN 30 (Storage)
    │
    ├─ Proxmox Node 1 (192.168.1.200)
    │   ├─ Management: 192.168.1.200
    │   └─ Cluster IP: 192.168.30.200
    │
    ├─ Proxmox Node 2 (192.168.1.201)
    │   ├─ Management: 192.168.1.201
    │   └─ Cluster IP: 192.168.30.201
    │
    └─ Proxmox Node 3 (192.168.1.202)
        ├─ Management: 192.168.1.202
        └─ Cluster IP: 192.168.30.202
```

---

## 🌐 IP Allocation Scheme

### VLAN 1: Management Network (192.168.1.0/24)

**Purpose**: Admin access, Proxmox web UI, SSH

| IP Range | Assignment | Notes |
|----------|------------|-------|
| 192.168.1.1 | Router/Gateway | Main internet gateway |
| 192.168.1.2-99 | Static devices | Workstations, laptops |
| 192.168.1.100-199 | DHCP pool | Dynamic devices |
| 192.168.1.200-209 | Proxmox hosts | PVE nodes |
| 192.168.1.210-219 | Infrastructure VMs | DNS, monitoring |
| 192.168.1.220-229 | Reserved | Future use |
| 192.168.1.240-254 | Network equipment | Switches, APs |

**Specific Assignments:**
```
192.168.1.1   - Router
192.168.1.200 - Proxmox Node 1 (pve1 or duality)
192.168.1.201 - Proxmox Node 2 (pve2) [future]
192.168.1.202 - Proxmox Node 3 (pve3) [future]
192.168.1.210 - DNS VM (Pi-hole)
192.168.1.211 - Monitoring VM (optional)
192.168.1.212 - Jump box / Bastion (optional)
```

### VLAN 10: Services Network (192.168.10.0/24)

**Purpose**: Application VMs, containers, web services

| IP Range | Assignment | Notes |
|----------|------------|-------|
| 192.168.10.1 | Proxmox bridge | Gateway for VMs |
| 192.168.10.10-19 | Core services | Reverse proxy, Git |
| 192.168.10.20-49 | Application VMs | Nextcloud, media, etc. |
| 192.168.10.50-99 | Containers (LXC) | Lightweight services |
| 192.168.10.100-199 | DHCP pool | Dynamic services |
| 192.168.10.200-254 | Reserved | Future expansion |

**Specific Assignments:**
```
192.168.10.1  - Proxmox gateway
192.168.10.10 - Traefik (reverse proxy)
192.168.10.11 - Gitea (Git server)
192.168.10.12 - Semaphore (automation UI)
192.168.10.20 - Nextcloud
192.168.10.21 - Jellyfin
192.168.10.22 - Home Assistant
192.168.10.30 - Media VM (Sonarr/Radarr/qBittorrent)
192.168.10.40 - AI/LLM VM (Ollama)
```

### VLAN 20: IoT/Cameras Network (192.168.20.0/24)

**Purpose**: Smart home devices, IP cameras, untrusted IoT

| IP Range | Assignment | Notes |
|----------|------------|-------|
| 192.168.20.1 | Proxmox bridge | Gateway for IoT |
| 192.168.20.10-49 | IP Cameras | Frigate sources |
| 192.168.20.50-99 | Smart home | Lights, sensors, etc. |
| 192.168.20.100-199 | DHCP pool | New IoT devices |
| 192.168.20.200 | Frigate NVR | Camera recorder |
| 192.168.20.201 | Home Assistant | HA on IoT VLAN |

**Specific Assignments:**
```
192.168.20.1   - Proxmox gateway
192.168.20.10  - Camera 1 (front door)
192.168.20.11  - Camera 2 (backyard)
192.168.20.12  - Camera 3 (garage)
192.168.20.50  - Smart thermostat
192.168.20.51  - Smart lights bridge
192.168.20.200 - Frigate NVR VM
```

### VLAN 30: Storage/Cluster Network (192.168.30.0/24) [Optional]

**Purpose**: Proxmox cluster communication, NFS/iSCSI, backups

| IP Range | Assignment | Notes |
|----------|------------|-------|
| 192.168.30.1 | Switch/Router | Storage gateway |
| 192.168.30.10 | NAS VM | Main storage |
| 192.168.30.11 | Backup server | Proxmox Backup Server |
| 192.168.30.100-109 | Proxmox cluster IPs | Corosync network |
| 192.168.30.200-209 | Proxmox storage IPs | NFS/iSCSI targets |

**Specific Assignments:**
```
192.168.30.10  - NAS VM (OpenMediaVault)
192.168.30.11  - Proxmox Backup Server
192.168.30.100 - PVE1 cluster IP
192.168.30.101 - PVE2 cluster IP
192.168.30.102 - PVE3 cluster IP
```

---

## 🔧 Proxmox Network Configuration

### Single-Node Configuration

**File**: `/etc/network/interfaces`

```bash
# Management Network (Native VLAN 1)
auto lo
iface lo inet loopback

# Physical interface
iface enp0s31f6 inet manual

# Management Bridge (No VLAN tag)
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.200/24
    gateway 192.168.1.1
    bridge-ports enp0s31f6
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
    # DNS
    dns-nameservers 1.1.1.1 8.8.8.8

# Services Network (VLAN 10)
auto vmbr0.10
iface vmbr0.10 inet manual
    vlan-raw-device vmbr0

auto vmbr10
iface vmbr10 inet static
    address 192.168.10.1/24
    bridge-ports vmbr0.10
    bridge-stp off
    bridge-fd 0
    # Enable IP forwarding for this bridge
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward

# IoT/Cameras Network (VLAN 20)
auto vmbr0.20
iface vmbr0.20 inet manual
    vlan-raw-device vmbr0

auto vmbr20
iface vmbr20 inet static
    address 192.168.20.1/24
    bridge-ports vmbr0.20
    bridge-stp off
    bridge-fd 0
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward

# Storage Network (VLAN 30) - Optional
auto vmbr0.30
iface vmbr0.30 inet manual
    vlan-raw-device vmbr0

auto vmbr30
iface vmbr30 inet static
    address 192.168.30.1/24
    bridge-ports vmbr0.30
    bridge-stp off
    bridge-fd 0
```

**Apply Configuration:**

```bash
# Test configuration
ifreload -a

# If successful, make permanent
systemctl restart networking

# Verify
ip addr show
bridge vlan show
```

### Multi-Node Configuration

**Additional Requirements:**
- Managed switch with VLAN support (Ubiquiti, Mikrotik, TP-Link, etc.)
- Dedicated NIC for cluster network (recommended)
- Corosync configured on VLAN 30

**File**: `/etc/network/interfaces` (Node 1)

```bash
# Physical interfaces
auto enp0s31f6
iface enp0s31f6 inet manual

# Optional: Dedicated 10GbE for storage
auto enp1s0
iface enp1s0 inet manual

# Management Bridge
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.200/24
    gateway 192.168.1.1
    bridge-ports enp0s31f6
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 10,20,30

# Services Network (VLAN 10)
auto vmbr10
iface vmbr10 inet static
    address 192.168.10.1/24
    bridge-ports vmbr0.10
    bridge-stp off
    bridge-fd 0

# IoT Network (VLAN 20)
auto vmbr20
iface vmbr20 inet static
    address 192.168.20.1/24
    bridge-ports vmbr0.20
    bridge-stp off
    bridge-fd 0

# Cluster Network (VLAN 30) - Dedicated interface
auto vmbr30
iface vmbr30 inet static
    address 192.168.30.200/24
    bridge-ports enp1s0
    bridge-stp off
    bridge-fd 0
    # MTU 9000 for jumbo frames (if supported)
    mtu 9000
```

**For Nodes 2 & 3**: Same config, adjust IPs:
- Node 2: 192.168.1.201, 192.168.30.201
- Node 3: 192.168.1.202, 192.168.30.202

---

## 🔒 Firewall Rules

### Proxmox Firewall Configuration

**Enable Datacenter Firewall:**

```bash
# Via CLI
pvesh set /cluster/firewall/options --enable 1

# Via Web UI
# Datacenter → Firewall → Options → Firewall: Yes
```

### Create Firewall Groups

**File**: `/etc/pve/firewall/cluster.fw`

```bash
[IPSET management]
192.168.1.0/24

[IPSET services]
192.168.10.0/24

[IPSET iot]
192.168.20.0/24

[IPSET storage]
192.168.30.0/24

[RULES]

# Allow SSH from management network only
GROUP management -i net0
IN SSH(ACCEPT) -source +management

# Allow Proxmox web UI from management network
GROUP management -i net0
IN ACCEPT -p tcp -dport 8006 -source +management

# Allow corosync (cluster) from storage network
GROUP storage -i net2
IN ACCEPT -p udp -dport 5404:5405 -source +storage

# IoT VLAN rules - block access to other VLANs
[group iot_isolation]
IN DROP -source +iot -dest +management
IN DROP -source +iot -dest +services
IN ACCEPT -source +iot -dest +iot
```

### Inter-VLAN Routing Rules

**Allow specific services access across VLANs:**

```bash
# Allow services to reach IoT (e.g., Home Assistant → IoT devices)
iptables -A FORWARD -i vmbr10 -o vmbr20 -j ACCEPT

# Allow IoT to reach DNS on services network
iptables -A FORWARD -i vmbr20 -o vmbr10 -p udp --dport 53 -j ACCEPT

# Block all other IoT → Services traffic
iptables -A FORWARD -i vmbr20 -o vmbr10 -j DROP

# Block IoT → Management completely
iptables -A FORWARD -i vmbr20 -o vmbr0 -j DROP

# Make persistent
apt install -y iptables-persistent
netfilter-persistent save
```

---

## 🖧 Router/Switch Configuration

### Managed Switch VLAN Setup

**Example: TP-Link TL-SG108E**

1. **Access switch web UI** (usually 192.168.0.1)
2. **Create VLANs:**
   - VLAN 1: Default/Management
   - VLAN 10: Services
   - VLAN 20: IoT
   - VLAN 30: Storage

3. **Port Configuration:**

| Port | Description | VLANs | Tagged/Untagged |
|------|-------------|-------|-----------------|
| 1 | Router uplink | 1,10,20,30 | Tagged all |
| 2 | Proxmox Node 1 | 1,10,20,30 | Tagged all |
| 3 | Proxmox Node 2 | 1,10,20,30 | Tagged all |
| 4 | Access Point | 1,10,20 | Tagged all |
| 5 | IP Camera 1 | 20 | Untagged VLAN 20 |
| 6 | IP Camera 2 | 20 | Untagged VLAN 20 |
| 7 | Admin PC | 1 | Untagged VLAN 1 |
| 8 | NAS (physical) | 30 | Untagged VLAN 30 |

4. **PVID Settings:**
   - Port 5,6: PVID 20 (IoT devices get untagged VLAN 20)
   - Port 7: PVID 1 (Admin PC on management)
   - Port 8: PVID 30 (NAS on storage)

### Router DHCP Configuration

**For each VLAN, configure separate DHCP scopes:**

**VLAN 1 (Management):**
```
Network: 192.168.1.0/24
DHCP Range: 192.168.1.100-192.168.1.199
Gateway: 192.168.1.1
DNS: 192.168.1.210 (Pi-hole, after deployment)
```

**VLAN 10 (Services):**
```
Network: 192.168.10.0/24
DHCP Range: 192.168.10.100-192.168.10.199
Gateway: 192.168.10.1 (Proxmox bridge)
DNS: 192.168.1.210
```

**VLAN 20 (IoT):**
```
Network: 192.168.20.0/24
DHCP Range: 192.168.20.100-192.168.20.199
Gateway: 192.168.20.1 (Proxmox bridge)
DNS: 192.168.1.210
Restrict Internet: Optional (firewall rules)
```

---

## 📋 VM Network Assignment

### Example VM Configurations

**Gitea VM (Services VLAN):**
```bash
# In Proxmox Web UI or Terraform
Network Device: vmbr10
VLAN Tag: (none, inherited from bridge)
IP: 192.168.10.11/24
Gateway: 192.168.10.1
```

**Camera VM (IoT VLAN):**
```bash
Network Device: vmbr20
IP: 192.168.20.200/24
Gateway: 192.168.20.1
```

**Multi-Homed VM (Access to multiple VLANs):**
```bash
# Example: Frigate needs both Services and IoT access
net0: vmbr10 (Services) - 192.168.10.25
net1: vmbr20 (IoT) - 192.168.20.200
```

### Terraform Network Configuration

```hcl
# In terraform/modules/vm-from-template/main.tf
network {
  model  = "virtio"
  bridge = var.network_bridge  # vmbr10 for services
  tag    = var.vlan_tag         # Optional VLAN tag
}

# For multi-NIC VMs
network {
  model  = "virtio"
  bridge = "vmbr10"
}

network {
  model  = "virtio"
  bridge = "vmbr20"
}
```

---

## ✅ Validation & Testing

### Test Network Connectivity

```bash
# From Proxmox host
ping -c 3 192.168.1.1      # Router
ping -c 3 192.168.10.1     # Services gateway
ping -c 3 192.168.20.1     # IoT gateway

# Test VLAN isolation (should fail)
ping -c 3 192.168.20.50    # IoT device from management (should timeout if firewall is configured)
```

### Test Inter-VLAN Routing

```bash
# From a VM on VLAN 10
ping -c 3 192.168.1.200    # Proxmox host (should work)
ping -c 3 192.168.20.1     # IoT gateway (depends on firewall rules)
```

### Verify VLAN Tagging

```bash
# On Proxmox host
apt install -y vlan
cat /proc/net/vlan/config

# Should show vmbr0.10, vmbr0.20, etc.
```

---

## 🆘 Troubleshooting

### VLAN Not Working

1. **Check if 8021q module is loaded:**
   ```bash
   lsmod | grep 8021q
   # If not loaded:
   modprobe 8021q
   echo "8021q" >> /etc/modules
   ```

2. **Verify interface configuration:**
   ```bash
   ip link show
   bridge vlan show
   ```

3. **Check switch configuration:**
   - Ensure trunk port allows all VLANs
   - Verify PVID settings for untagged devices

### No Internet on VLAN

1. **Check gateway:**
   ```bash
   ip route show
   ```

2. **Enable IP forwarding:**
   ```bash
   sysctl -w net.ipv4.ip_forward=1
   echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
   ```

3. **Check NAT/masquerade:**
   ```bash
   iptables -t nat -A POSTROUTING -o vmbr0 -j MASQUERADE
   ```

### Can't Access VMs

1. **Verify VM network settings in Proxmox**
2. **Check VM firewall (iptables inside VM)**
3. **Verify VM has correct IP/gateway/DNS**

---

## 📚 Additional Resources

- **VLAN Best Practices**: https://www.cisco.com/c/en/us/support/docs/lan-switching/8021q/17056-741-4.html
- **Proxmox Network Configuration**: https://pve.proxmox.com/wiki/Network_Configuration
- **Proxmox Firewall**: https://pve.proxmox.com/wiki/Firewall

---

**Network Guide Version**: 1.0
**Last Updated**: 2025-12-01
**Author**: Automated Homelab Project
