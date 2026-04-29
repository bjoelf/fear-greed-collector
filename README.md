# Fear & Greed Index Collector

A Python application that collects the CNN Fear & Greed Index data and maintains a historical database in CSV format.

## Overview

The Fear & Greed Index is a measure of market sentiment developed by CNN Business. It analyzes 7 different indicators to gauge whether investors are feeling fearful or greedy:

- Market Momentum (S&P 500 vs 125-day moving average)
- Stock Price Strength
- Stock Price Breadth (52-week highs and lows)
- Put and Call Options
- Market Volatility (VIX)
- Safe Haven Demand (stocks vs bonds)
- Junk Bond Demand

The index ranges from 0 (Extreme Fear) to 100 (Extreme Greed).

## Features

- Fetches current Fear & Greed Index value
- Downloads historical data (1 year of daily values)
- Maintains a CSV database without duplicates
- Appends new data automatically when run periodically
- Displays current market sentiment

## Installation

1. Clone this repository or download the files
2. Install dependencies:

```bash
pip install -r requirements.txt
```

## Usage

### Fetch Data

Run the script to fetch and update the data:

```bash
python3 fetch_fear_greed.py
```

The script will:
- Fetch the latest Fear & Greed Index data from CNN
- Download historical data points
- Save/append to `fear_greed_data.csv`
- Automatically skip duplicate entries

### Data Format

The CSV file contains the following columns:

- `timestamp_ms`: Unix timestamp in milliseconds
- `datetime`: Human-readable date and time
- `score`: Fear & Greed score (0-100)
- `rating`: Text rating (extreme_fear, fear, neutral, greed, extreme_greed)

### Example Output

```
Fetching Fear & Greed Index data...
✓ Added 254 new data points to fear_greed_data.csv

Current Fear & Greed Index:
  Score: 63.83
  Rating: GREED
  Timestamp: 2026-04-29T11:58:16+00:00
  Previous close: 63.80
  1 week ago: 68.60
  1 month ago: 14.47
  1 year ago: 32.74

✓ Data collection complete!
```

## Raspberry Pi Deployment

For automated deployment to a Raspberry Pi:

```bash
./deploy_to_rpi.sh 192.168.0.101 pi
```

This will:
- Copy files to your Pi
- Set up Python environment
- Configure automatic data collection (Sunday & Wednesday at 04:00 UTC)
- Start collecting data immediately

See [RPI_DEPLOYMENT.md](RPI_DEPLOYMENT.md) for detailed instructions, troubleshooting, and management commands.

### Quick Setup Scripts

- `./setup.sh` - Set up Python environment locally or on Pi
- `./setup_systemd.sh` - Configure systemd timer (recommended)
- `./setup_cron.sh` - Configure cron job (alternative)
- `./find_rpi.sh` - Find your Raspberry Pi on the network

## Data Source

Data is fetched from the official CNN Fear & Greed Index API:
- API: `https://production.dataviz.cnn.io/index/fearandgreed/graphdata`
- Web: https://edition.cnn.com/markets/fear-and-greed

## License

MIT License - Feel free to use and modify as needed.

## Notes

- The Fear & Greed Index updates throughout the trading day
- Historical data goes back approximately 1 year
- The API provides ~254 daily data points
- New data points are added automatically without creating duplicates
