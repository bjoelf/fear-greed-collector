# Raspberry Pi Deployment Guide

This guide explains how to deploy the Fear & Greed Index collector to your Raspberry Pi.

## Prerequisites

- Raspberry Pi with Raspbian/Raspberry Pi OS installed
- SSH enabled on the Raspberry Pi
- Network connection (same network as your computer)
- Python 3.7+ on the Raspberry Pi

## Quick Start

### 1. Find Your Raspberry Pi

If you don't know your Pi's IP address:

```bash
./find_rpi.sh
```

This will scan your network and show potential Raspberry Pi devices.

### 2. Deploy to Raspberry Pi

Once you have the IP address:

```bash
./deploy_to_rpi.sh 192.168.0.101 pi
```

Replace `192.168.0.101` with your Pi's IP address and `pi` with your username if different.

The deployment script will:
- ✓ Copy all necessary files to the Pi
- ✓ Set up a Python virtual environment
- ✓ Install dependencies
- ✓ Configure systemd timer for automatic data collection (twice weekly)
- ✓ Start collecting data immediately

## Manual Setup (Alternative)

If you prefer to set things up manually or the automatic deployment doesn't work:

### 1. Copy Files to Pi

```bash
scp -r * pi@192.168.0.101:~/fear-greed-collector/
```

### 2. SSH to the Pi

```bash
ssh pi@192.168.0.101
cd ~/fear-greed-collector
```

### 3. Run Setup

```bash
./setup.sh
```

### 4. Choose Collection Method

**Option A: Systemd Timer (Recommended)**

```bash
./setup_systemd.sh
```

Advantages:
- Runs on boot
- Better logging
- More reliable
- Modern approach

**Option B: Cron Job**

```bash
./setup_cron.sh
```

Advantages:
- Simpler
- Traditional
- Works on older systems

## Monitoring on Raspberry Pi

### Check Service Status

```bash
# Check timer status
sudo systemctl status fear-greed-collector.timer

# Check service status
sudo systemctl status fear-greed-collector.service

# List all timers
systemctl list-timers
```

### View Logs

```bash
# Service logs
tail -f ~/fear-greed-collector/logs/service.log

# Systemd journal
journalctl -u fear-greed-collector.service -f

# Cron logs (if using cron)
tail -f ~/fear-greed-collector/logs/cron.log
```

### View Collected Data

```bash
# See latest entries
tail ~/fear-greed-collector/fear_greed_data.csv

# Count entries
wc -l ~/fear-greed-collector/fear_greed_data.csv

# See statistics
grep -o 'greed\|fear\|neutral' ~/fear-greed-collector/fear_greed_data.csv | sort | uniq -c
```

## Management Commands

### Manual Data Collection

```bash
cd ~/fear-greed-collector
source venv/bin/activate
python fetch_fear_greed.py
```

### Stop/Start Automatic Collection

**Systemd:**
```bash
# Stop
sudo systemctl stop fear-greed-collector.timer

# Start
sudo systemctl start fear-greed-collector.timer

# Disable (prevent auto-start on boot)
sudo systemctl disable fear-greed-collector.timer

# Enable (auto-start on boot)
sudo systemctl enable fear-greed-collector.timer
```

**Cron:**
```bash
# Edit crontab
crontab -e

# Comment out or delete the line with fetch_fear_greed.py
```

### Change Collection Frequency

**Systemd:**
```bash
# Edit the timer
sudo systemctl edit fear-greed-collector.timer

# Add (for 2-hour interval):
[Timer]
OnUnitActiveSec=2h

# Save and reload
sudo systemctl daemon-reload
sudo systemctl restart fear-greed-collector.timer
```

**Cron:**
```bash
# Edit crontab
crontab -e

# Change the schedule:
# Every 2 hours: 0 */2 * * *
# Every 4 hours: 0 */4 * * *
# Market hours only (9-5, Mon-Fri): 0 9-17 * * 1-5
```

## Data Backup

### Download Data from Pi

```bash
# Download CSV
scp pi@192.168.0.101:~/fear-greed-collector/fear_greed_data.csv .

# Download all data
rsync -avz pi@192.168.0.101:~/fear-greed-collector/ ./rpi-backup/
```

### Automated Backup (on your computer)

Create a backup script:

```bash
#!/bin/bash
# backup_fear_greed.sh
BACKUP_DIR="$HOME/backups/fear-greed"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"
scp pi@192.168.0.101:~/fear-greed-collector/fear_greed_data.csv \
    "$BACKUP_DIR/fear_greed_data_$DATE.csv"
```

Add to your crontab to run daily:
```bash
0 23 * * * /path/to/backup_fear_greed.sh
```

## Troubleshooting

### Data Not Collecting

1. Check if the service is running:
   ```bash
   sudo systemctl status fear-greed-collector.service
   ```

2. Check logs for errors:
   ```bash
   tail -50 ~/fear-greed-collector/logs/service.log
   ```

3. Test manually:
   ```bash
   cd ~/fear-greed-collector
   source venv/bin/activate
   python fetch_fear_greed.py
   ```

### Network Issues

If the fetch fails with connection errors:

1. Check internet connection:
   ```bash
   ping -c 3 edition.cnn.com
   ```

2. Check DNS resolution:
   ```bash
   nslookup production.dataviz.cnn.io
   ```

3. Try fetching with curl:
   ```bash
   curl -I https://production.dataviz.cnn.io/index/fearandgreed/graphdata
   ```

### SSH Connection Issues

1. Verify Pi is on network:
   ```bash
   ping 192.168.0.101
   ```

2. Check SSH service on Pi:
   ```bash
   ssh -v pi@192.168.0.101
   ```

3. Verify SSH keys or password

## Updating the Collector

When you make changes to the code:

```bash
# From your development machine
cd /home/bjorn/dev/fear-greed-collector
./deploy_to_rpi.sh 192.168.0.101 pi
```

This will sync the latest code and restart services.

## Uninstall

To remove the collector from your Pi:

```bash
# SSH to Pi
ssh pi@192.168.0.101

# Stop and disable services
sudo systemctl stop fear-greed-collector.timer
sudo systemctl disable fear-greed-collector.timer
sudo rm /etc/systemd/system/fear-greed-collector.*
sudo systemctl daemon-reload

# Remove cron job (if applicable)
crontab -e  # Delete the fear-greed line

# Remove files
rm -rf ~/fear-greed-collector
```

## Tips

- The index updates throughout trading days, so hourly collection is ideal
- Data accumulates over time - monitor disk space occasionally
- Keep the CSV file as a backup before major updates
- Consider collecting only during market hours to save resources
- Use `screen` or `tmux` if running tests over SSH

## Further Reading

- [Systemd Timer Units](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Cron Syntax](https://crontab.guru/)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
