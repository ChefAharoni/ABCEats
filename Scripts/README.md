# ABCEats Data Generation Scripts

This directory contains scripts to pre-download restaurant data and bundle it with your app for immediate availability on first launch.

## Quick Start

1. **Generate the data:**

   ```bash
   ./Scripts/generate_data.sh
   ```

2. **Add the generated file to Xcode:**

   - Open your Xcode project
   - Right-click on the ABCEats folder in the navigator
   - Select "Add Files to ABCEats"
   - Choose `ABCEats/restaurants_data.json`
   - Make sure "Add to target" is checked for your main app target

3. **Build and run your app:**
   - The data will now be available immediately on first launch!

## What These Scripts Do

### `generate_data.sh`

A shell script that runs the Swift data generator and provides clear output.

### `generate_restaurant_data.swift`

A Swift script that:

- Downloads all restaurant data from the NYC API
- Processes and filters the data (removes duplicates, validates coordinates)
- Saves the processed data as JSON
- Creates two copies:
  - `Scripts/restaurants_data.json` (for reference)
  - `ABCEats/restaurants_data.json` (for bundling with the app)

## How It Works

1. **On App Launch:** The `RestaurantDataService` first tries to load data from UserDefaults (if the user has used the app before)

2. **If No Local Data:** It automatically loads the pre-bundled `restaurants_data.json` file

3. **Data Persistence:** Once loaded, the data is saved to UserDefaults for future launches

4. **Background Updates:** The app can still download fresh data in the background for updates

## Benefits

- ✅ **Instant Launch:** No waiting for data download on first open
- ✅ **Offline Capability:** App works immediately even without internet
- ✅ **Better UX:** Users see content right away
- ✅ **Reduced API Calls:** Less load on the NYC API
- ✅ **Faster Development:** No need to wait for downloads during testing

## Updating the Data

To update the bundled data with fresh information:

1. Run the generation script again:

   ```bash
   ./Scripts/generate_data.sh
   ```

2. The new data will replace the existing `restaurants_data.json` file

3. Build and distribute your app with the updated data

## File Structure

```
ABCEats/
├── Scripts/
│   ├── generate_data.sh              # Main script to run
│   ├── generate_restaurant_data.swift # Swift data generator
│   └── README.md                     # This file
├── ABCEats/
│   ├── restaurants_data.json         # Bundled data (generated)
│   └── ... (other app files)
└── ...
```

## Troubleshooting

### Script fails to run

- Make sure you're in the ABCEats project root directory
- Ensure you have internet connection (needed to download from NYC API)
- Check that Swift is installed: `swift --version`

### No data in app

- Verify `restaurants_data.json` is added to your Xcode project target
- Check the console for any error messages
- Ensure the file is in the correct location: `ABCEats/restaurants_data.json`

### Large file size

- The JSON file can be several MB due to the large number of restaurants
- This is normal and expected for a comprehensive restaurant database
- The file is compressed when the app is distributed through the App Store
