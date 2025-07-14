#!/bin/bash

# Setup Build Phase for Data Copying
# This script adds a build phase to automatically copy restaurant data

echo "🔧 Setting up build phase for automatic data copying..."

# Check if we're in the right directory
if [ ! -f "ABCEats.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the ABCEats project root directory"
    exit 1
fi

# Get the absolute path to the copy script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPY_SCRIPT="$SCRIPT_DIR/copy_data_to_bundle.sh"

# Check if the copy script exists
if [ ! -f "$COPY_SCRIPT" ]; then
    echo "❌ Error: copy_data_to_bundle.sh not found at $COPY_SCRIPT"
    exit 1
fi

echo "📝 Adding build phase to Xcode project..."
echo "   Script: $COPY_SCRIPT"

# Create a temporary file for the modified project
TEMP_PROJECT="ABCEats.xcodeproj/project_temp.pbxproj"

# Read the project file and add the build phase
python3 -c "
import re
import sys

# Read the project file
with open('ABCEats.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Check if the build phase already exists
if 'Copy Restaurant Data' in content:
    print('✅ Build phase already exists')
    sys.exit(0)

# Find the Resources build phase for the main target
# Look for the pattern that ends the Resources phase
resources_pattern = r'(.*?)(/\* End PBXResourcesBuildPhase \*/)'

match = re.search(resources_pattern, content, re.DOTALL)
if not match:
    print('❌ Could not find Resources build phase')
    sys.exit(1)

before_resources = match.group(1)
after_resources = match.group(2)

# Generate a unique ID for the new build phase (using timestamp)
import time
unique_id = str(int(time.time() * 1000))[-8:]  # Last 8 digits of timestamp

# Create the new build phase
new_build_phase = f'''
		{unique_id} /* Copy Restaurant Data */ = {{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = \"Copy Restaurant Data\";
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/bash;
			shellScript = \"\\\"${{SRCROOT}}/Scripts/copy_data_to_bundle.sh\\\"\";
		}};
'''

# Insert the new build phase before the Resources phase
modified_content = before_resources + new_build_phase + after_resources

# Also need to add the build phase to the target's buildPhases
target_pattern = r'(.*?)(buildPhases = \()(.*?)(\);)(.*?)'
target_match = re.search(target_pattern, modified_content, re.DOTALL)

if target_match:
    before_target = target_match.group(1)
    build_phases_start = target_match.group(2)
    build_phases_content = target_match.group(3)
    build_phases_end = target_match.group(4)
    after_target = target_match.group(5)
    
    # Add our build phase reference to the buildPhases list
    new_build_phases = build_phases_content.rstrip() + f'''
				{unique_id} /* Copy Restaurant Data */,
'''
    
    final_content = before_target + build_phases_start + new_build_phases + build_phases_end + after_target
else:
    print('❌ Could not find target buildPhases')
    sys.exit(1)

# Write the modified content
with open('ABCEats.xcodeproj/project.pbxproj', 'w') as f:
    f.write(final_content)

print('✅ Successfully added build phase to Xcode project')
print('   Build phase ID: ' + unique_id)
print('   Script: ${{SRCROOT}}/Scripts/copy_data_to_bundle.sh')
"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Build phase setup completed!"
    echo ""
    echo "📋 What this does:"
    echo "   • Every time you build the app, it will automatically copy"
    echo "     the latest restaurants_data.json to the app bundle"
    echo "   • No manual copying needed anymore"
    echo ""
    echo "🔧 To use this:"
    echo "   1. Run ./Scripts/generate_data.sh to update the data"
    echo "   2. Build the app normally in Xcode (⌘+B)"
    echo "   3. The data will be automatically included"
    echo ""
    echo "💡 You can also use the automated build script:"
    echo "   ./Scripts/build_with_data.sh"
else
    echo "❌ Failed to add build phase"
    exit 1
fi 