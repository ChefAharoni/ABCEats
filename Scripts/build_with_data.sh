#!/bin/bash

# ABCEats Build Script with Data Generation
# This script generates fresh restaurant data and then builds the app

echo "🏗️  ABCEats Build with Data Generation"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "ABCEats.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the ABCEats project root directory"
    exit 1
fi

# Step 1: Generate fresh data
echo "📊 Step 1: Generating fresh restaurant data..."
if ./Scripts/generate_data.sh; then
    echo "✅ Data generation completed"
else
    echo "❌ Data generation failed"
    exit 1
fi

echo ""

# Step 2: Build the app
echo "🏗️  Step 2: Building the app..."
echo "📱 This will build the app with the fresh data included"

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ xcodebuild not found. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Build the app
if xcodebuild -project ABCEats.xcodeproj -scheme ABCEats -destination 'platform=iOS Simulator,name=iPhone 15' build; then
    echo ""
    echo "🎉 Build completed successfully!"
    echo "📱 Your app now includes the latest restaurant data"
    echo ""
    echo "💡 To run on device:"
    echo "   1. Open ABCEats.xcodeproj in Xcode"
    echo "   2. Select your device as the target"
    echo "   3. Build and run (⌘+R)"
else
    echo ""
    echo "❌ Build failed"
    exit 1
fi 