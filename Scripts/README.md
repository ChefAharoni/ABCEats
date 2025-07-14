# ABCEats Scripts

This directory contains scripts for managing restaurant data and building the ABCEats app.

## Scripts Overview

### Data Generation

- `generate_data.sh` - Downloads and processes restaurant data from NYC Health API
- `generate_restaurant_data.swift` - Swift script that fetches and formats the data

### Build Automation

- `build_with_data.sh` - Generates fresh data and builds the app
- `copy_data_to_bundle.sh` - Copies restaurant data to the app bundle during build
- `setup_build_phase.sh` - Sets up automatic data copying in Xcode build phases

## Automated Data Integration

To ensure the latest restaurant data is automatically included in every build:

### Option 1: Automatic Setup (Recommended)

```bash
# Run this once to set up automatic data copying
./Scripts/setup_build_phase.sh
```

This will add a build phase to your Xcode project that automatically copies `restaurants_data.json` to the app bundle during every build.

### Option 2: Manual Setup

If the automatic setup doesn't work, you can manually add the build phase in Xcode:

1. Open `ABCEats.xcodeproj` in Xcode
2. Select the `ABCEats` target
3. Go to the "Build Phases" tab
4. Click the "+" button and select "New Run Script Phase"
5. Name it "Copy Restaurant Data"
6. Add this script:
   ```bash
   "${SRCROOT}/Scripts/copy_data_to_bundle.sh"
   ```
7. Make sure this phase runs before the "Copy Bundle Resources" phase

### Option 3: Use the Automated Build Script

```bash
# This generates fresh data and builds the app
./Scripts/build_with_data.sh
```

## Workflow

### For Development

1. **Generate fresh data:**

   ```bash
   ./Scripts/generate_data.sh
   ```

2. **Build the app:**
   - In Xcode: ⌘+B (Build)
   - Or use: `./Scripts/build_with_data.sh`

### For Production

1. **Generate and build:**

   ```bash
   ./Scripts/build_with_data.sh
   ```

2. **Archive and distribute:**
   - Use Xcode's Archive feature
   - The data will be automatically included

## Data File Location

- **Generated data:** `Scripts/restaurants_data.json`
- **App bundle:** `ABCEats/restaurants_data.json` (copied during build)
- **Runtime access:** The app loads from the bundle on first launch

## Troubleshooting

### Build Phase Not Working

- Check that `copy_data_to_bundle.sh` is executable: `chmod +x Scripts/copy_data_to_bundle.sh`
- Verify the script path in the build phase matches your project structure
- Check Xcode build logs for any script errors

### Data Not Loading in App

- Ensure `restaurants_data.json` exists in `Scripts/` directory
- Check that the file is being copied to the app bundle (check build logs)
- Verify the app can find the file at runtime (check console logs)

### Large File Size

- The JSON file can be large (several MB)
- Consider compressing or optimizing the data if needed
- The app will load faster with smaller files
