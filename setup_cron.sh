#!/bin/bash
# Setup script to add cron job for fetching Fear & Greed Index data

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FETCH_SCRIPT="$SCRIPT_DIR/fetch_fear_greed.py"

# Check if virtual environment exists and use it
if [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    PYTHON_PATH="$SCRIPT_DIR/venv/bin/python"
    echo "✓ Using virtual environment Python"
else
    PYTHON_PATH=$(which python3)
    echo "⚠ Virtual environment not found, using system Python"
    echo "  Run ./setup.sh first for a cleaner setup"
fi

# Make sure the fetch script is executable
chmod +x "$FETCH_SCRIPT"

echo ""
echo "The Fear & Greed Index updates throughout the trading day."
echo "Choose how often to fetch the data:"
echo ""
echo "  1) Twice weekly (Sun & Wed at 04:00 UTC) - recommended"
echo "  2) Every hour"
echo "  3) Every 2 hours"
echo "  4) Every 4 hours"
echo "  5) Market hours only (9 AM - 5 PM EST, weekdays)"
echo "  6) Custom interval"
echo ""
read -p "Enter your choice [1-6]: " choice

case $choice in
    1)
        CRON_SCHEDULE="0 4 * * 0,3"
        DESCRIPTION="twice weekly (Sun & Wed at 04:00 UTC)"
        ;;
    2)
        CRON_SCHEDULE="0 * * * *"
        DESCRIPTION="every hour"
        ;;
    3)
        CRON_SCHEDULE="0 */2 * * *"
        DESCRIPTION="every 2 hours"
        ;;
    4)
        CRON_SCHEDULE="0 */4 * * *"
        DESCRIPTION="every 4 hours"
        ;;
    5)
        CRON_SCHEDULE="0 9-17 * * 1-5"
        DESCRIPTION="every hour during market hours (9 AM - 5 PM, Mon-Fri)"
        ;;
    6)
        echo ""
        echo "Enter cron schedule (e.g., '0 * * * *' for hourly):"
        read -p "> " CRON_SCHEDULE
        DESCRIPTION="with custom schedule: $CRON_SCHEDULE"
        ;;
    *)
        echo "Invalid choice. Using default: twice weekly"
        CRON_SCHEDULE="0 4 * * 0,3"
        DESCRIPTION="twice weekly (Sun & Wed at 04:00 UTC)"
        ;;
esac

echo ""
echo "Current crontab:"
crontab -l 2>/dev/null
echo ""

# Create temporary cron file
TEMP_CRON=$(mktemp)

# Get existing crontab (if any)
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Remove any existing fear-greed job
sed -i '/fetch_fear_greed.py/d' "$TEMP_CRON"

# Add new cron job
echo "$CRON_SCHEDULE cd $SCRIPT_DIR && $PYTHON_PATH $FETCH_SCRIPT >> $SCRIPT_DIR/logs/cron.log 2>&1" >> "$TEMP_CRON"

# Install new crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

echo "✓ Cron job installed!"
echo ""
echo "The script will run $DESCRIPTION."
echo "Check logs at: $SCRIPT_DIR/logs/cron.log"
echo ""
echo "To change the interval: crontab -e"
echo "Common schedules:"
echo "  0 * * * *       = every hour (on the hour)"
echo "  0 */2 * * *     = every 2 hours"
echo "  30 * * * *      = every hour at :30 past"
echo "  0 9-17 * * 1-5  = every hour 9am-5pm, weekdays only"
echo ""
echo "To remove the cron job: crontab -e (then delete the line)"
echo "To view current jobs: crontab -l"
