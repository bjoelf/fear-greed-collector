#!/bin/bash
# Find Raspberry Pi on the network
# This script scans your network for devices that might be a Raspberry Pi

echo "🔍 Scanning network for Raspberry Pi..."
echo "========================================"
echo ""

# Get your local network range
LOCAL_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
NETWORK=$(echo $LOCAL_IP | cut -d. -f1-3)

echo "Your IP: $LOCAL_IP"
echo "Scanning network: $NETWORK.0/24"
echo ""

# Method 1: Check common Pi IPs first
echo "1️⃣  Checking common Raspberry Pi IPs..."
for IP in 100 101 102 103 150 200; do
    timeout 1 ping -c 1 $NETWORK.$IP >/dev/null 2>&1 && echo "   ✓ $NETWORK.$IP is responding"
done
echo ""

# Method 2: Use nmap if available (faster and shows hostnames)
if command -v nmap &> /dev/null; then
    echo "2️⃣  Using nmap to scan network (this may take a minute)..."
    sudo nmap -sn $NETWORK.0/24 2>/dev/null | grep -B 2 -i "raspberry\|pi" || echo "   No devices with 'raspberry' or 'pi' in hostname found"
    echo ""
    
    echo "3️⃣  All active hosts on network:"
    sudo nmap -sn $NETWORK.0/24 2>/dev/null | grep "Nmap scan report" | awk '{print $5, $6}'
    echo ""
else
    echo "2️⃣  nmap not installed (install with: sudo apt install nmap)"
    echo ""
fi

# Method 3: Use arp-scan if available (shows MAC addresses - Pi foundation has specific vendors)
if command -v arp-scan &> /dev/null; then
    echo "3️⃣  Using arp-scan to find devices..."
    sudo arp-scan --localnet 2>/dev/null | grep -i "raspberry\|b827eb\|dca632\|e45f01" || echo "   No Raspberry Pi MAC addresses found"
    echo ""
else
    echo "3️⃣  arp-scan not installed (install with: sudo apt install arp-scan)"
    echo ""
fi

# Method 4: Check ARP cache for recently seen devices
echo "4️⃣  Recently seen devices (ARP cache):"
arp -n | grep "$NETWORK" | awk '{print $1 " - " $3}'
echo ""

# Method 5: MDNS/Bonjour scan (Pi might be at raspberrypi.local)
echo "5️⃣  Trying common Raspberry Pi hostname..."
if timeout 2 ping -c 1 raspberrypi.local >/dev/null 2>&1; then
    PI_IP=$(ping -c 1 raspberrypi.local 2>/dev/null | grep PING | awk -F'[()]' '{print $2}')
    echo "   ✓ Found 'raspberrypi.local' at $PI_IP"
else
    echo "   ✗ 'raspberrypi.local' not responding"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Troubleshooting tips:"
echo ""
echo "If no Pi found:"
echo "  • Check if the Pi is powered on (look for green LED)"
echo "  • Make sure Pi is connected to same network"
echo "  • Check your router's DHCP client list"
echo "  • Connect a monitor/keyboard to Pi and check 'hostname -I'"
echo ""
echo "Try SSH to found IP:"
echo "  ssh pi@<IP_ADDRESS>      # Default user is usually 'pi'"
echo "  ssh ubuntu@<IP_ADDRESS>  # If running Ubuntu"
echo ""
echo "Test specific IP:"
echo "  ping <IP_ADDRESS>"
echo "  ssh -v pi@<IP_ADDRESS>   # Verbose mode shows why connection fails"
