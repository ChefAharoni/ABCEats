#!/bin/bash

# Simple Setup for Automatic Data Copying
# This script provides instructions for setting up automatic data copying

echo "🔧 Setting up automatic data copying for ABCEats"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "ABCEats.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the ABCEats project root directory"
    exit 1
fi

echo "✅ Found Xcode project"
echo ""

echo "📋 Manual Setup Instructions:"
echo "============================="
echo ""
echo "1. Open ABCEats.xcodeproj in Xcode"
echo "2. Select the 'ABCEats' target in the project navigator"
echo "3. Go to the 'Build Phases' tab"
echo "4. Click the '+' button and select 'New Run Script Phase'"
echo "5. Name it 'Copy Restaurant Data'"
echo "6. Add this script to the phase:"
echo ""
echo "   \${SRCROOT}/Scripts/copy_data_to_bundle.sh"
echo ""
echo "7. Make sure this phase runs BEFORE the 'Copy Bundle Resources' phase"
echo "   (You can drag to reorder the phases)"
echo ""
echo "8. Save the project (⌘+S)"
echo ""

echo "🎯 What this does:"
echo "=================="
echo "• Every time you build the app, it will automatically copy"
echo "  the latest restaurants_data.json to the app bundle"
echo "• No manual copying needed anymore"
echo "• The app will have fresh data on every build"
echo ""

echo "🔧 To use this:"
echo "==============="
echo "1. Run ./Scripts/generate_data.sh to update the data"
echo "2. Build the app normally in Xcode (⌘+B)"
echo "3. The data will be automatically included"
echo ""

echo "💡 Alternative: Use the automated build script"
echo "=============================================="
echo "./Scripts/build_with_data.sh"
echo ""

echo "✅ Setup instructions complete!"
echo ""
echo "After following these steps, your app will automatically"
echo "include the latest restaurant data in every build." 