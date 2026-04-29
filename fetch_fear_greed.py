#!/usr/bin/env python3
"""
Fear & Greed Index Data Collector
Fetches the CNN Fear & Greed Index and historical data, saving to CSV
"""

import requests
import json
import csv
import os
from datetime import datetime
from pathlib import Path


# API endpoint for Fear & Greed Index
API_URL = "https://production.dataviz.cnn.io/index/fearandgreed/graphdata"

# Headers to avoid bot detection
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
    'Referer': 'https://edition.cnn.com/'
}

# Output file
DATA_FILE = "fear_greed_data.csv"


def fetch_fear_greed_data():
    """Fetch Fear & Greed Index data from CNN API"""
    try:
        response = requests.get(API_URL, headers=HEADERS, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data: {e}")
        return None


def load_existing_data():
    """Load existing data from CSV file"""
    existing_timestamps = set()
    
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                existing_timestamps.add(int(row['timestamp_ms']))
    
    return existing_timestamps


def save_to_csv(data):
    """Save Fear & Greed data to CSV file"""
    if not data:
        print("No data to save")
        return
    
    # Load existing timestamps to avoid duplicates
    existing_timestamps = load_existing_data()
    
    # Check if file exists to determine if we need to write headers
    file_exists = os.path.exists(DATA_FILE)
    
    # Extract historical data
    historical = data.get('fear_and_greed_historical', {}).get('data', [])
    
    # Count new entries
    new_entries = 0
    
    # Open file in append mode
    with open(DATA_FILE, 'a', newline='') as f:
        fieldnames = ['timestamp_ms', 'datetime', 'score', 'rating']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        # Write header only if file is new
        if not file_exists:
            writer.writeheader()
        
        # Write historical data points
        for point in historical:
            timestamp_ms = int(point['x'])
            
            # Skip if already exists
            if timestamp_ms in existing_timestamps:
                continue
            
            # Convert timestamp to readable datetime
            dt = datetime.fromtimestamp(timestamp_ms / 1000)
            
            writer.writerow({
                'timestamp_ms': timestamp_ms,
                'datetime': dt.strftime('%Y-%m-%d %H:%M:%S'),
                'score': round(point['y'], 2),
                'rating': point['rating']
            })
            new_entries += 1
    
    if new_entries > 0:
        print(f"✓ Added {new_entries} new data points to {DATA_FILE}")
    else:
        print(f"✓ No new data points (all {len(historical)} entries already exist)")
    
    # Display current status
    current = data.get('fear_and_greed', {})
    if current:
        print(f"\nCurrent Fear & Greed Index:")
        print(f"  Score: {current['score']:.2f}")
        print(f"  Rating: {current['rating'].upper()}")
        print(f"  Timestamp: {current['timestamp']}")
        print(f"  Previous close: {current['previous_close']:.2f}")
        print(f"  1 week ago: {current['previous_1_week']:.2f}")
        print(f"  1 month ago: {current['previous_1_month']:.2f}")
        print(f"  1 year ago: {current['previous_1_year']:.2f}")


def main():
    """Main function"""
    print("Fetching Fear & Greed Index data...")
    
    data = fetch_fear_greed_data()
    
    if data:
        save_to_csv(data)
        print("\n✓ Data collection complete!")
    else:
        print("✗ Failed to fetch data")
        exit(1)


if __name__ == "__main__":
    main()
