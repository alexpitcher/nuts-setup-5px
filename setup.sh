#!/bin/bash
set -e

echo "[*] Installing NUT and Apache..."
apt update
apt install -y nut nut-cgi apache2

echo "[*] Enabling Apache CGI support..."
a2enmod cgid
echo "Listen 82" > /etc/apache2/ports.conf

cat <<EOF > /etc/apache2/sites-available/nut.conf
<VirtualHost *:82>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/lib/cgi-bin/nut
    <Directory "/usr/lib/cgi-bin/nut">
        Options +ExecCGI
        AddHandler cgi-script .cgi
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/nut_error.log
    CustomLog \${APACHE_LOG_DIR}/nut_access.log combined
</VirtualHost>
EOF

a2ensite nut.conf
systemctl reload apache2

echo "[*] Detecting USB UPS device..."
UPS_DEV=$(lsusb | grep -iE 'eaton|ups' | awk '{print $2 "-" $4}' | sed 's/://')
USB_PATH=$(readlink -f /dev/bus/usb/*/* | grep "$(lsusb | grep -iE 'eaton|ups' | awk '{print $6}' | cut -d: -f1 | tr '[:upper:]' '[:lower:]')")

echo "[*] Attempting to unbind UPS device..."
UPS_IFACE=$(udevadm info -a -p $(udevadm info -q path -n ${USB_PATH}) | grep -m1 'KERNEL=="' | cut -d'"' -f2)
echo -n "$UPS_IFACE:1.0" > /sys/bus/usb/drivers/usbfs/unbind || echo "[!] Unbind failed or unnecessary"

cat <<EOF > /etc/udev/rules.d/52-nut-usb.rules
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0463", ATTR{idProduct}=="ffff", MODE="0660", GROUP="nut", ENV{DEVTYPE}=="usb_device", RUN+="/bin/sh -c 'echo -n $UPS_IFACE:1.0 > /sys/bus/usb/drivers/usbfs/unbind'"
EOF

cat <<EOF > /etc/nut/ups.conf
[eaton5px]
    driver = usbhid-ups
    port = auto
    desc = "Eaton 5PX"
    vendorid = 0463
    productid = ffff
EOF

cat <<EOF > /etc/nut/upsd.conf
LISTEN 127.0.0.1 3493
EOF

cat <<EOF > /etc/nut/upsd.users
[admin]
    password = admin
    actions = SET
    instcmds = ALL

[upsmon]
    password = admin
    upsmon master
EOF

cat <<EOF > /etc/nut/upsmon.conf
MONITOR eaton5px@localhost 1 upsmon admin master
MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h +0"
POLLFREQ 5
POLLFREQALERT 5
DEADTIME 15
POWERDOWNFLAG /etc/killpower
FINALDELAY 5
EOF

# Set mode to netserver
echo "MODE=netserver" > /etc/nut/nut.conf

udevadm control --reload
udevadm trigger
systemctl restart nut-server
sleep 2
systemctl restart nut-monitor

upsc eaton5px || echo "[!] UPS not responding, check config"
echo "[*] Setup complete. Web UI should be available on port 82."
