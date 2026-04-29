#!/usr/bin/env python3
"""
Plot Fear & Greed Index historical data
"""

import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

DATA_FILE = "fear_greed_data.csv"


def plot_fear_greed():
    """Create a visualization of the Fear & Greed Index over time"""
    
    # Read the CSV file
    df = pd.read_csv(DATA_FILE)
    
    # Convert datetime string to datetime object
    df['datetime'] = pd.to_datetime(df['datetime'])
    
    # Sort by datetime
    df = df.sort_values('datetime')
    
    # Create the plot
    fig, ax = plt.subplots(figsize=(14, 7))
    
    # Plot the score
    ax.plot(df['datetime'], df['score'], linewidth=2, color='#2E86AB', alpha=0.8)
    
    # Fill areas based on rating
    ax.fill_between(df['datetime'], 0, df['score'], 
                     where=(df['score'] <= 25), alpha=0.3, color='#D32F2F', label='Extreme Fear')
    ax.fill_between(df['datetime'], 25, df['score'], 
                     where=(df['score'] > 25) & (df['score'] <= 45), alpha=0.3, color='#FF6F00', label='Fear')
    ax.fill_between(df['datetime'], 45, df['score'], 
                     where=(df['score'] > 45) & (df['score'] <= 55), alpha=0.3, color='#FDD835', label='Neutral')
    ax.fill_between(df['datetime'], 55, df['score'], 
                     where=(df['score'] > 55) & (df['score'] <= 75), alpha=0.3, color='#7CB342', label='Greed')
    ax.fill_between(df['datetime'], 75, df['score'], 
                     where=(df['score'] > 75), alpha=0.3, color='#388E3C', label='Extreme Greed')
    
    # Add horizontal reference lines
    ax.axhline(y=25, color='gray', linestyle='--', alpha=0.3, linewidth=1)
    ax.axhline(y=50, color='gray', linestyle='--', alpha=0.5, linewidth=1)
    ax.axhline(y=75, color='gray', linestyle='--', alpha=0.3, linewidth=1)
    
    # Customize the plot
    ax.set_xlabel('Date', fontsize=12, fontweight='bold')
    ax.set_ylabel('Fear & Greed Index', fontsize=12, fontweight='bold')
    ax.set_title('CNN Fear & Greed Index - Historical Data', fontsize=16, fontweight='bold', pad=20)
    ax.set_ylim(0, 100)
    ax.grid(True, alpha=0.2)
    ax.legend(loc='upper left', framealpha=0.9)
    
    # Add current value annotation
    last_row = df.iloc[-1]
    ax.annotate(f'Current: {last_row["score"]:.1f}\n({last_row["rating"].capitalize()})',
                xy=(last_row['datetime'], last_row['score']),
                xytext=(10, 10), textcoords='offset points',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', alpha=0.7),
                fontsize=10, fontweight='bold')
    
    # Rotate x-axis labels
    plt.xticks(rotation=45, ha='right')
    
    # Tight layout
    plt.tight_layout()
    
    # Save the plot
    output_file = 'fear_greed_plot.png'
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    print(f"✓ Plot saved to {output_file}")
    
    # Show the plot
    plt.show()


def print_statistics():
    """Print some basic statistics about the data"""
    df = pd.read_csv(DATA_FILE)
    
    print("\n=== Fear & Greed Index Statistics ===")
    print(f"Total data points: {len(df)}")
    print(f"\nScore Statistics:")
    print(f"  Current: {df.iloc[-1]['score']:.2f} ({df.iloc[-1]['rating'].upper()})")
    print(f"  Mean: {df['score'].mean():.2f}")
    print(f"  Median: {df['score'].median():.2f}")
    print(f"  Min: {df['score'].min():.2f}")
    print(f"  Max: {df['score'].max():.2f}")
    print(f"  Std Dev: {df['score'].std():.2f}")
    
    print(f"\nRating Distribution:")
    rating_counts = df['rating'].value_counts()
    for rating, count in rating_counts.items():
        percentage = (count / len(df)) * 100
        print(f"  {rating.capitalize()}: {count} ({percentage:.1f}%)")
    
    # Date range
    df['datetime'] = pd.to_datetime(df['datetime'])
    print(f"\nDate Range:")
    print(f"  From: {df['datetime'].min().strftime('%Y-%m-%d')}")
    print(f"  To: {df['datetime'].max().strftime('%Y-%m-%d')}")
    print(f"  Days: {(df['datetime'].max() - df['datetime'].min()).days}")


if __name__ == "__main__":
    print_statistics()
    print("\nGenerating plot...")
    plot_fear_greed()
