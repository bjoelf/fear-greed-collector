#!/bin/bash
# Complete setup script for Fear & Greed Index collector

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🚀 Setting up Fear & Greed Index Collector..."
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Create logs directory
mkdir -p logs

echo ""
echo "✅ Setup complete!"
echo ""
echo "To use the collector:"
echo "  1. Activate the environment: source venv/bin/activate"
echo "  2. Test the fetcher: python fetch_fear_greed.py"
echo "  3. Set up automatic collection: ./setup_cron.sh or ./setup_systemd.sh"
echo ""
echo "When you're done: deactivate"
