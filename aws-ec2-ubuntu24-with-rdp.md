# Setting Up Ubuntu 24.04 EC2 Instance with RDP Access

This document details the complete process of provisioning an Ubuntu 24.04 EC2 instance in AWS with Remote Desktop Protocol (RDP) access, including troubleshooting steps for common issues encountered.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Instance Provisioning](#instance-provisioning)
- [Initial Setup via SSH](#initial-setup-via-ssh)
- [Troubleshooting](#troubleshooting)
- [Final Working Configuration](#final-working-configuration)
- [Connection Details](#connection-details)

---

## Prerequisites

- AWS CLI configured with appropriate profile
- SSH key pair created in AWS and `.pem` file downloaded locally
- Security group with ports 22 (SSH) and 3389 (RDP) open to your IP
- VPC subnet in your desired availability zone

## Instance Provisioning

### 1. Find the Latest Ubuntu 24.04 AMI

```bash
aws ec2 describe-images --region <YOUR_REGION> \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd*/ubuntu-*-24.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].[ImageId,Name]' \
  --output table
```

> **Note:** Owner ID `099720109477` is Canonical's official AWS account for Ubuntu AMIs.

### 2. Identify Available Resources

```bash
# Find subnets in your VPC
aws ec2 describe-subnets --region <YOUR_REGION> \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,VpcId,CidrBlock]' --output table

# Find or create a security group with SSH and RDP access
aws ec2 describe-security-groups --region <YOUR_REGION> \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table

# Check available instance types in your AZ
aws ec2 describe-instance-type-offerings --region <YOUR_REGION> \
  --location-type availability-zone \
  --filters "Name=location,Values=<YOUR_AZ>" "Name=instance-type,Values=t3.*" \
  --query 'InstanceTypeOfferings[*].InstanceType' --output text
```

### 3. Launch the EC2 Instance

```bash
aws ec2 run-instances --region <YOUR_REGION> \
  --image-id <AMI_ID> \
  --instance-type t3.2xlarge \
  --subnet-id <SUBNET_ID> \
  --security-group-ids <SECURITY_GROUP_ID> \
  --key-name <YOUR_KEY_PAIR_NAME> \
  --associate-public-ip-address \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ubuntu24-rdp}]' \
  --output table
```

**Recommended Instance Specs:**
| Property | Value |
|----------|-------|
| Instance Type | t3.2xlarge (8 vCPUs, 32GB RAM) or larger |
| OS | Ubuntu 24.04 LTS (Noble Numbat) |
| Disk | 100GB gp3 (adjust based on needs) |

> **Note:** For desktop/GUI workloads, t3.xlarge (4 vCPUs, 16GB) is the minimum recommended. t3.2xlarge provides a smoother experience.

---

## Initial Setup via SSH

### 1. Connect to the Instance

```bash
ssh -i /path/to/your-key.pem ubuntu@<INSTANCE_PUBLIC_IP>
```

### 2. Install Desktop Environment and xrdp

```bash
sudo apt update
sudo apt install -y ubuntu-desktop xrdp
sudo systemctl enable xrdp
```

### 3. Set Password for Ubuntu User

```bash
sudo passwd ubuntu
# Or via command line (replace 'your-secure-password' with actual password):
echo 'ubuntu:your-secure-password' | sudo chpasswd
```

---

## Troubleshooting

### Issue 1: xrdp Service Won't Start - Missing Config File

**Symptom:**
```
xrdp-sesman.service: Failed with result 'exit-code'
Config file /etc/xrdp/sesman.ini does not exist
```

**Cause:** dpkg was interrupted during initial package installation.

**Solution:**
```bash
sudo dpkg --configure -a
sudo apt-get install --reinstall -y xrdp
```

### Issue 2: xrdp Service Starts but Login Fails (PAM Authentication Error)

**Symptom:**
```
[ERROR] pam_authenticate failed: Authentication failure
[INFO ] AUTHFAIL: user=ubuntu
```

**Cause:** xrdp user not in ssl-cert group.

**Solution:**
```bash
sudo usermod -a -G ssl-cert ubuntu
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp xrdp-sesman
```

### Issue 3: X Server Not Found

**Symptom:**
```
Error calling exec (executable: /usr/lib/xorg/Xorg) returned errno: 2,
description: No such file or directory
```

**Cause:** Xorg and xorgxrdp packages not installed.

**Solution:**
```bash
sudo apt-get install -y xorg xorgxrdp
sudo systemctl restart xrdp xrdp-sesman
```

### Issue 4: GNOME Desktop Crashes ("Oh no! Something has gone wrong")

**Symptom:** After successful RDP login, GNOME Shell displays error:
```
"Oh no! Something has gone wrong. Please logout and login again"
```

**Cause:** GNOME Shell requires hardware acceleration (GPU) which is not available through xrdp's software rendering. GNOME on Wayland/Xorg needs 3D acceleration that xrdp cannot provide.

**Solution:** Install and configure XFCE desktop environment instead of GNOME.

```bash
# Install XFCE
sudo apt-get install -y xfce4 xfce4-goodies

# Configure xrdp to use XFCE
echo 'xfce4-session' > ~/.xsession
chmod +x ~/.xsession

# Restart xrdp
sudo systemctl restart xrdp xrdp-sesman
```

---

## Final Working Configuration

### Required Packages

```bash
# Core packages
sudo apt update
sudo apt install -y xfce4 xfce4-goodies xrdp xorg xorgxrdp

# Configure xrdp to use XFCE
echo 'xfce4-session' > ~/.xsession
chmod +x ~/.xsession

# Add users to required groups
sudo adduser xrdp ssl-cert

# Set user password for RDP login
echo 'ubuntu:ubuntu123' | sudo chpasswd

# Enable and start services
sudo systemctl enable xrdp
sudo systemctl restart xrdp xrdp-sesman
```

### Security Group Rules Required

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| SSH | TCP | 22 | Your IP/32 |
| RDP | TCP | 3389 | Your IP/32 |

> **Security Note:** Restrict RDP and SSH access to your specific IP address. Avoid using `0.0.0.0/0` (open to the world) for these ports.

### Verify Services Are Running

```bash
# Check xrdp status
sudo systemctl status xrdp

# Check xrdp-sesman status
sudo systemctl status xrdp-sesman

# Verify port 3389 is listening
sudo ss -tlnp | grep 3389
```

---

## Connection Details

### RDP Client Configuration

- **Host:** `<INSTANCE_PUBLIC_IP>`
- **Port:** 3389 (default)
- **Username:** ubuntu
- **Password:** (the password you set with `passwd` or `chpasswd`)

Use any RDP client:
- **Windows:** Built-in Remote Desktop Connection (`mstsc`)
- **macOS:** Microsoft Remote Desktop (from App Store)
- **Linux:** Remmina, rdesktop, or xfreerdp

### SSH Access

```bash
ssh -i /path/to/your-key.pem ubuntu@<INSTANCE_PUBLIC_IP>
```

### Remote Command Execution

```bash
ssh -i /path/to/your-key.pem ubuntu@<INSTANCE_PUBLIC_IP> "command here"
```

---

## Key Learnings

1. **GNOME doesn't work well with xrdp** - GNOME Shell requires hardware acceleration which xrdp cannot provide. Always use XFCE, MATE, or other lightweight desktop environments for RDP access.

2. **Package installation order matters** - Install xorg and xorgxrdp explicitly; they may not be pulled in as dependencies of ubuntu-desktop.

3. **ssl-cert group is required** - The xrdp user must be in the ssl-cert group to read TLS certificates.

4. **Use ~/.xsession for session configuration** - This file determines which desktop environment starts when connecting via RDP.

5. **Password authentication required** - xrdp requires password authentication; SSH key-based auth doesn't work for RDP sessions.

---

## Complete Setup Script

For a fresh Ubuntu 24.04 instance, save this as `setup-rdp.sh` and run it:

```bash
#!/bin/bash
set -e

# Configuration - CHANGE THESE
RDP_PASSWORD="your-secure-password-here"

echo "=== Ubuntu 24.04 RDP Setup Script ==="

# Update system
echo "[1/6] Updating system packages..."
sudo apt update

# Install XFCE and xrdp
echo "[2/6] Installing XFCE desktop and xrdp..."
sudo apt install -y xfce4 xfce4-goodies xrdp xorg xorgxrdp

# Configure xrdp to use XFCE
echo "[3/6] Configuring xrdp to use XFCE..."
echo 'xfce4-session' > ~/.xsession
chmod +x ~/.xsession

# Add xrdp to ssl-cert group
echo "[4/6] Configuring user groups..."
sudo adduser xrdp ssl-cert

# Set password for RDP login
echo "[5/6] Setting RDP password..."
echo "ubuntu:${RDP_PASSWORD}" | sudo chpasswd

# Enable and restart services
echo "[6/6] Starting xrdp services..."
sudo systemctl enable xrdp
sudo systemctl restart xrdp xrdp-sesman

# Verify
echo ""
echo "=== Setup Complete ==="
sudo systemctl status xrdp --no-pager
echo ""
echo "RDP is ready! Connect using:"
echo "  Host: $(curl -s ifconfig.me)"
echo "  Port: 3389"
echo "  Username: ubuntu"
echo "  Password: (the password you configured)"
```

### Usage

```bash
# Make it executable
chmod +x setup-rdp.sh

# Edit the script to set your password
nano setup-rdp.sh

# Run it
./setup-rdp.sh
```

---

## Additional Resources

- [Ubuntu 24.04 LTS Release Notes](https://wiki.ubuntu.com/NobleNumbat/ReleaseNotes)
- [xrdp GitHub Repository](https://github.com/neutrinolabs/xrdp)
- [XFCE Documentation](https://docs.xfce.org/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/index.html)

---

*Last updated: November 2025*
