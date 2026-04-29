#!/bin/bash
# Deploy Fear & Greed Index collector to Raspberry Pi
# Usage: ./deploy_to_rpi.sh [pi_address] [pi_user]

set -e

# Configuration
RPI_HOST="${1:-192.168.0.101}"
RPI_USER="${2:-pi}"
REMOTE_DIR="/home/$RPI_USER/fear-greed-collector"
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🚀 Deploying Fear & Greed Index Collector to Raspberry Pi"
echo "=========================================================="
echo "Target: $RPI_USER@$RPI_HOST"
echo "Remote directory: $REMOTE_DIR"
echo ""

# Test SSH connection
echo "📡 Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 "$RPI_USER@$RPI_HOST" "echo 'Connection successful'"; then
    echo "❌ Cannot connect to $RPI_USER@$RPI_HOST"
    echo "   Make sure SSH is enabled and the IP is correct"
    echo "   Try: ./find_rpi.sh to locate your Raspberry Pi"
    exit 1
fi

echo "✓ SSH connection successful"
echo ""

# Create remote directory
echo "📁 Creating remote directory..."
ssh "$RPI_USER@$RPI_HOST" "mkdir -p $REMOTE_DIR"

# Copy necessary files
echo "📤 Copying files to Raspberry Pi..."
rsync -avz --progress \
    --exclude 'venv/' \
    --exclude '.git/' \
    --exclude '__pycache__/' \
    --exclude '*.pyc' \
    --exclude '*.log' \
    --exclude '*.png' \
    --exclude '.gitignore' \
    "$LOCAL_DIR/" "$RPI_USER@$RPI_HOST:$REMOTE_DIR/"

echo "✓ Files copied"
echo ""

# Run setup on Raspberry Pi
echo "⚙️  Setting up environment on Raspberry Pi..."
ssh "$RPI_USER@$RPI_HOST" "cd $REMOTE_DIR && bash setup.sh"

echo ""
echo "🔧 Installing systemd service..."

# Create systemd service on the Pi
ssh "$RPI_USER@$RPI_HOST" "bash -s" << 'ENDSSH'
cd ~/fear-greed-collector

# Create systemd service file
sudo tee /etc/systemd/system/fear-greed-collector.service > /dev/null << 'EOF'
[Unit]
Description=Fear & Greed Index Data Collector
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=/home/$USER/fear-greed-collector
ExecStart=/home/$USER/fear-greed-collector/venv/bin/python /home/$USER/fear-greed-collector/fetch_fear_greed.py
StandardOutput=append:/home/$USER/fear-greed-collector/logs/service.log
StandardError=append:/home/$USER/fear-greed-collector/logs/service.log
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Replace $USER with actual username
sudo sed -i "s/\$USER/$USER/g" /etc/systemd/system/fear-greed-collector.service

# Create timer file
sudo tee /etc/systemd/system/fear-greed-collector.timer > /dev/null << 'EOF'
[Unit]
Description=Run Fear & Greed Index collector twice weekly (Sun & Wed at 04:00 UTC)
After=network-online.target

[Timer]
OnCalendar=Sun *-*-* 04:00:00
OnCalendar=Wed *-*-* 04:00:00
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Create logs directory
mkdir -p ~/fear-greed-collector/logs

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the timer
sudo systemctl enable fear-greed-collector.timer
sudo systemctl start fear-greed-collector.timer

# Run once immediately to test
echo ""
echo "🧪 Running initial test fetch..."
sudo systemctl start fear-greed-collector.service

# Wait a moment and check status
sleep 3
sudo systemctl status fear-greed-collector.service --no-pager || true

ENDSSH

echo ""
echo "✅ Deployment complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Your Fear & Greed Index collector is now running!"
echo ""
echo "Collection schedule: Sunday & Wednesday at 04:00 UTC"
echo ""
echo "To check status on the Pi:"
echo "  ssh $RPI_USER@$RPI_HOST"
echo "  sudo systemctl status fear-greed-collector.timer"
echo "  sudo systemctl status fear-greed-collector.service"
echo "  tail -f ~/fear-greed-collector/logs/service.log"
echo ""
echo "Data will be collected hourly and saved to:"
echo "  ~/fear-greed-collector/fear_greed_data.csv"
echo ""
echo "To modify the collection interval:"
echo "  1. SSH to the Pi: ssh $RPI_USER@$RPI_HOST"
echo "  2. Edit timer: sudo nano /etc/systemd/system/fear-greed-collector.timer"
echo "  3. Change OnCalendar lines (e.g., 'OnCalendar=daily' for daily)"
echo "  4. Reload: sudo systemctl daemon-reload"
echo "  5. Restart: sudo systemctl restart fear-greed-collector.timer"
echo ""
