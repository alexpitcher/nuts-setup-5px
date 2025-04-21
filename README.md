# nuts-setup-5px
NUTS setup bash script to run on proxmox to configure a USB connected EATON 5PX.

# NUT UPS Monitoring Setup Script for Proxmox with Eaton 5PX

This script automates the configuration of a USB-connected Eaton 5PX UPS on a Proxmox node using NUT (Network UPS Tools). It also sets up a basic web interface using Apache, bound to port 82, to view UPS status via CGI.

---

## Features

- Auto-detects and unbinds the USB UPS (if needed)
- Installs and configures NUT in **netserver** mode
- Sets up `ups.conf`, `upsd.conf`, `upsd.users`, and `upsmon.conf` with:
  - UPS name: `eaton5px`
  - Username/password: `admin` / `admin`
- Adds udev rules to detach the UPS from `usbhid` properly
- Configures Apache2 and NUT CGI tools for a web interface on port 82
- Starts all necessary services and verifies UPS communication

---

## Requirements

- Tested on Debian 12 (Proxmox)
- Eaton 5PX UPS via USB
- Root or sudo access

---

## Usage

1. Copy the script to your Proxmox node:

   ```bash
   curl -O https://example.com/nut-setup.sh
   chmod +x nut-setup.sh```

2.	Run the script:
3.	
   ```bash
   sudo ./nut-setup.sh```

3. Access the web interface:

   ```http://<your-server-ip>:82/cgi-bin/nut/upsstats.cgi```
