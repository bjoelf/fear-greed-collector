# Fear & Greed Index Collector - Quick Reference

## Common Commands

### Local Development

```bash
# First-time setup
./setup.sh
source venv/bin/activate

# Fetch data manually
python fetch_fear_greed.py

# Generate plot
python plot_fear_greed.py

# View data
head -20 fear_greed_data.csv
tail -10 fear_greed_data.csv
```

### Raspberry Pi Deployment

```bash
# Find your Pi
./find_rpi.sh

# Deploy everything
./deploy_to_rpi.sh 192.168.0.101 pi

# Check status (on Pi)
ssh pi@192.168.0.101
sudo systemctl status fear-greed-collector.timer
tail -f ~/fear-greed-collector/logs/service.log
```

### Data Analysis

```bash
# Count total data points
wc -l fear_greed_data.csv

# Count by rating
grep -o 'extreme_fear\|fear\|neutral\|greed\|extreme_greed' fear_greed_data.csv | sort | uniq -c

# Find highest/lowest scores
sort -t',' -k3 -n fear_greed_data.csv | tail -5  # Highest
sort -t',' -k3 -n fear_greed_data.csv | head -6  # Lowest (skip header)

# Recent entries
tail -20 fear_greed_data.csv
```

## File Structure

```
fear-greed-collector/
├── fetch_fear_greed.py      # Main data collector
├── plot_fear_greed.py        # Visualization script
├── fear_greed_data.csv       # Historical data
├── requirements.txt          # Python dependencies
├── README.md                 # Project overview
├── RPI_DEPLOYMENT.md         # Deployment guide
├── QUICKREF.md               # This file
├── setup.sh                  # Environment setup
├── setup_systemd.sh          # Systemd timer setup
├── setup_cron.sh             # Cron job setup
├── deploy_to_rpi.sh          # Full RPI deployment
└── find_rpi.sh               # Network scanner
```

## Collection Schedules

### Cron Format
```
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of week (0 - 6, Sunday = 0)
# │ │ │ │ │
# * * * * * command

0 4 * * 0,3      # Sundays and Wednesdays at 04:00 UTC
0 * * * *        # Every hour
0 */2 * * *      # Every 2 hours
30 * * * *       # Every hour at :30 past
0 9-17 * * 1-5   # 9am-5pm, Mon-Fri (market hours)
*/30 * * * *     # Every 30 minutes
```

### Systemd Timer Intervals
```
# Calendar-based (specific days/times)
OnCalendar=Sun *-*-* 04:00:00       # Sundays at 04:00 UTC
OnCalendar=Wed *-*-* 04:00:00       # Wednesdays at 04:00 UTC
OnCalendar=daily                    # Daily at midnight
OnCalendar=Mon..Fri 09:00:00        # Weekdays at 09:00

# Interval-based
OnUnitActiveSec=1h    # Every hour
OnUnitActiveSec=2h    # Every 2 hours
OnUnitActiveSec=30m   # Every 30 minutes
OnUnitActiveSec=4h    # Every 4 hours
```

## Index Ratings

| Score Range | Rating        | Color/Meaning      |
|-------------|---------------|--------------------|
| 0 - 25      | Extreme Fear  | Red - Panic        |
| 25 - 45     | Fear          | Orange - Worried   |
| 45 - 55     | Neutral       | Yellow - Balanced  |
| 55 - 75     | Greed         | Light Green - Optimistic |
| 75 - 100    | Extreme Greed | Dark Green - Euphoric |

## API Information

**Endpoint:** `https://production.dataviz.cnn.io/index/fearandgreed/graphdata`

**Returns:**
- Current index value
- Historical comparisons (1 day, 1 week, 1 month, 1 year)
- ~254 daily data points (1 year of history)

**Update Frequency:** Updates throughout trading days

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Cannot connect to RPI" | Run `./find_rpi.sh` to locate Pi |
| "Module not found" | Run `./setup.sh` to install dependencies |
| No new data | Check internet: `ping edition.cnn.com` |
| Script not running | Check timer: `systemctl --user status fear-greed-fetch.timer` |
| Permission denied | Make executable: `chmod +x *.sh` |

## Backup & Download

```bash
# From RPI to local
scp pi@192.168.0.101:~/fear-greed-collector/fear_greed_data.csv ./backup/

# Full sync from RPI
rsync -avz pi@192.168.0.101:~/fear-greed-collector/ ./rpi-backup/

# Full sync to RPI
rsync -avz --exclude 'venv/' ./ pi@192.168.0.101:~/fear-greed-collector/
```

## Python Usage

```python
import pandas as pd

# Load data
df = pd.read_csv('fear_greed_data.csv')
df['datetime'] = pd.to_datetime(df['datetime'])

# Basic stats
print(df['score'].describe())

# Filter by rating
extreme_fear = df[df['rating'] == 'extreme_fear']
extreme_greed = df[df['rating'] == 'extreme_greed']

# Recent trend
recent = df.tail(30)
print(f"30-day average: {recent['score'].mean():.2f}")
```

## Resources

- CNN Fear & Greed Page: https://edition.cnn.com/markets/fear-and-greed
- Cron Syntax Helper: https://crontab.guru/
- Systemd Documentation: https://www.freedesktop.org/software/systemd/man/
