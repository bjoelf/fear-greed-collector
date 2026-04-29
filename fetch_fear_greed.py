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
    """Load existing data from CSV file, returning dates and their max timestamp"""
    existing_dates = {}  # date -> (timestamp_ms, score)
    
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                timestamp_ms = int(row['timestamp_ms'])
                dt = datetime.fromtimestamp(timestamp_ms / 1000)
                date_key = dt.strftime('%Y-%m-%d')
                score = float(row['score'])
                
                # Keep the latest timestamp for each date
                if date_key not in existing_dates or timestamp_ms > existing_dates[date_key][0]:
                    existing_dates[date_key] = (timestamp_ms, score)
    
    return existing_dates


def save_to_csv(data):
    """Save Fear & Greed data to CSV file"""
    if not data:
        print("No data to save")
        return
    
    # Load existing dates to avoid duplicates (one entry per date)
    existing_dates = load_existing_data()
    
    # Check if file exists to determine if we need to write headers
    file_exists = os.path.exists(DATA_FILE)
    
    # Extract historical data
    historical = data.get('fear_and_greed_historical', {}).get('data', [])
    
    # Group by date and keep only the latest entry per date
    date_entries = {}
    for point in historical:
        timestamp_ms = int(point['x'])
        dt = datetime.fromtimestamp(timestamp_ms / 1000)
        date_key = dt.strftime('%Y-%m-%d')
        score = round(point['y'], 2)
        
        # Keep the latest timestamp for each date
        if date_key not in date_entries or timestamp_ms > date_entries[date_key]['timestamp_ms']:
            date_entries[date_key] = {
                'timestamp_ms': timestamp_ms,
                'datetime': dt.strftime('%Y-%m-%d %H:%M:%S'),
                'score': score,
                'rating': point['rating']
            }
    
    # Count new entries
    new_entries = 0
    updated_entries = 0
    
    # Collect entries to write
    entries_to_write = []
    for date_key, entry in date_entries.items():
        if date_key in existing_dates:
            # Check if this is newer data for the same date
            if entry['timestamp_ms'] > existing_dates[date_key][0]:
                # We have newer data for this date - we'll need to rebuild the file
                updated_entries += 1
                existing_dates[date_key] = (entry['timestamp_ms'], entry['score'])
            # Skip if we already have this or newer data
            continue
        else:
            # Completely new date
            entries_to_write.append(entry)
            new_entries += 1
    
    # If we have updates, rebuild the entire file with latest data per date
    if updated_entries > 0:
        print(f"⚠ {updated_entries} date(s) have newer data - rebuilding file...")
        rebuild_csv_file(existing_dates, date_entries)
        print(f"✓ File rebuilt with latest data for each date")
    # Otherwise, just append new entries
    elif entries_to_write:
        with open(DATA_FILE, 'a', newline='') as f:
            fieldnames = ['timestamp_ms', 'datetime', 'score', 'rating']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            
            # Write header only if file is new
            if not file_exists:
                writer.writeheader()
            
            # Sort by timestamp before writing
            entries_to_write.sort(key=lambda x: x['timestamp_ms'])
            
            for entry in entries_to_write:
                writer.writerow(entry)
        
        print(f"✓ Added {new_entries} new data points to {DATA_FILE}")
    else:
        print(f"✓ No new data points (all dates already have current data)")
    
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


def rebuild_csv_file(existing_dates, new_date_entries):
    """Rebuild CSV file with updated data"""
    import tempfile
    import shutil
    
    # Merge existing and new data, keeping newest for each date
    all_dates = existing_dates.copy()
    for date_key, entry in new_date_entries.items():
        timestamp_ms = entry['timestamp_ms']
        score = entry['score']
        if date_key not in all_dates or timestamp_ms > all_dates[date_key][0]:
            all_dates[date_key] = (timestamp_ms, score)
    
    # Read all current data
    all_entries = []
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                timestamp_ms = int(row['timestamp_ms'])
                dt = datetime.fromtimestamp(timestamp_ms / 1000)
                date_key = dt.strftime('%Y-%m-%d')
                
                # Only keep if this is the latest entry for this date
                if all_dates.get(date_key, (0,))[0] == timestamp_ms:
                    all_entries.append(row)
    
    # Add new entries that weren't in the original file
    for date_key, entry in new_date_entries.items():
        # Check if this entry's timestamp matches the latest for its date
        if all_dates[date_key][0] == entry['timestamp_ms']:
            # Check if it's not already in all_entries
            if not any(int(e['timestamp_ms']) == entry['timestamp_ms'] for e in all_entries):
                all_entries.append(entry)
    
    # Sort all entries by timestamp
    all_entries.sort(key=lambda x: int(x['timestamp_ms']))
    
    # Write to temporary file then replace original
    with tempfile.NamedTemporaryFile(mode='w', delete=False, newline='') as tmp:
        fieldnames = ['timestamp_ms', 'datetime', 'score', 'rating']
        writer = csv.DictWriter(tmp, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_entries)
        tmp_name = tmp.name
    
    # Replace original file
    shutil.move(tmp_name, DATA_FILE)


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
