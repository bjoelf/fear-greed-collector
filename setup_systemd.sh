#!/bin/bash
# Setup systemd timer for Fear & Greed Index data collection
# This is a modern alternative to cron

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FETCH_SCRIPT="$SCRIPT_DIR/fetch_fear_greed.py"

# Check if virtual environment exists
if [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    PYTHON_PATH="$SCRIPT_DIR/venv/bin/python"
else
    PYTHON_PATH=$(which python3)
fi

SERVICE_FILE="$HOME/.config/systemd/user/fear-greed-fetch.service"
TIMER_FILE="$HOME/.config/systemd/user/fear-greed-fetch.timer"

# Create systemd user directory if it doesn't exist
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$SCRIPT_DIR/logs"

echo "Choose fetch interval:"
echo "  1) Twice weekly (Sun & Wed at 04:00 UTC) - recommended"
echo "  2) Every hour"
echo "  3) Every 2 hours"
echo "  4) Every 4 hours"
echo ""
read -p "Enter your choice [1-4]: " choice

case $choice in
    2)
        TIMER_TYPE="interval"
        TIMER_INTERVAL="1h"
        DESCRIPTION="every hour"
        ;;
    3)
        TIMER_TYPE="interval"
        TIMER_INTERVAL="2h"
        DESCRIPTION="every 2 hours"
        ;;
    4)
        TIMER_TYPE="interval"
        TIMER_INTERVAL="4h"
        DESCRIPTION="every 4 hours"
        ;;
    *)
        TIMER_TYPE="calendar"
        DESCRIPTION="twice weekly (Sun & Wed at 04:00 UTC)"
        ;;
esac

# Create service file
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Fetch Fear & Greed Index

[Service]
Type=oneshot
WorkingDirectory=$SCRIPT_DIR
ExecStart=$PYTHON_PATH $FETCH_SCRIPT
StandardOutput=append:$SCRIPT_DIR/logs/systemd.log
StandardError=append:$SCRIPT_DIR/logs/systemd.log
EOF

# Create timer file
if [ "$TIMER_TYPE" = "calendar" ]; then
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=Run Fear & Greed Index fetch $DESCRIPTION

[Timer]
OnCalendar=Sun *-*-* 04:00:00
OnCalendar=Wed *-*-* 04:00:00
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF
else
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=Run Fear & Greed Index fetch $DESCRIPTION

[Timer]
OnBootSec=2min
OnUnitActiveSec=$TIMER_INTERVAL
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF
fi

# Reload systemd and enable the timer
systemctl --user daemon-reload
systemctl --user enable fear-greed-fetch.timer
systemctl --user start fear-greed-fetch.timer

echo ""
echo "✓ Systemd timer installed and started!"
echo ""
echo "The script will run $DESCRIPTION."
echo "Check logs at: $SCRIPT_DIR/logs/systemd.log"
echo ""
echo "Useful commands:"
echo "  systemctl --user status fear-greed-fetch.timer   # Check timer status"
echo "  systemctl --user list-timers                     # List all timers"
echo "  systemctl --user stop fear-greed-fetch.timer     # Stop timer"
echo "  systemctl --user disable fear-greed-fetch.timer  # Disable timer"
echo "  journalctl --user -u fear-greed-fetch.service    # View service logs"
