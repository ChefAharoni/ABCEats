#!/bin/bash

# Restaurant Data Generation Script
# This script downloads restaurant data from NYC API and saves it for bundling with the app

echo "🍽️  ABCEats Restaurant Data Generator"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "ABCEats.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the ABCEats project root directory"
    exit 1
fi

# Create Scripts directory if it doesn't exist
mkdir -p Scripts

echo "🚀 Starting data generation..."
echo "📅 Started at: $(date)"
echo ""

# Run the Swift script
if swift Scripts/generate_restaurant_data.swift; then
    echo ""
    echo "✅ Data generation completed successfully!"
    echo "📊 Check the generated files:"
    echo "   - Scripts/restaurants_data.json"
    echo "   - ABCEats/restaurants_data.json"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Add restaurants_data.json to your Xcode project"
    echo "   2. Build and run your app"
    echo "   3. The data will be available immediately on first launch!"
else
    echo ""
    echo "❌ Data generation failed!"
    exit 1
fi 