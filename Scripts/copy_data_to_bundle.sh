#!/bin/bash

# Copy Restaurant Data to App Bundle
# This script is run as a build phase to ensure the latest data is included

echo "📦 Copying restaurant data to app bundle..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source and destination paths
SOURCE_FILE="$PROJECT_ROOT/Scripts/restaurants_data.json"
DESTINATION_DIR="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "⚠️  Warning: restaurants_data.json not found at $SOURCE_FILE"
    echo "   This means the data generation script hasn't been run yet."
    echo "   The app will work but may need to download data on first launch."
    exit 0  # Don't fail the build, just warn
fi

# Create destination directory if it doesn't exist
mkdir -p "$DESTINATION_DIR"

# Copy the file
cp "$SOURCE_FILE" "$DESTINATION_DIR/"

if [ $? -eq 0 ]; then
    echo "✅ Successfully copied restaurants_data.json to app bundle"
    echo "   Source: $SOURCE_FILE"
    echo "   Destination: $DESTINATION_DIR/restaurants_data.json"
    
    # Show file size for verification
    FILE_SIZE=$(ls -lh "$SOURCE_FILE" | awk '{print $5}')
    echo "   File size: $FILE_SIZE"
else
    echo "❌ Failed to copy restaurants_data.json"
    exit 1
fi 