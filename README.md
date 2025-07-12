# ABCEats - NYC Restaurant Health Grades App

A native iOS application that allows users to search for restaurants in New York City and view their health inspection grades. The app provides comprehensive search functionality, interactive maps, and offline capabilities.

## Features

### 🔍 Advanced Search

- **Restaurant Name**: Search by restaurant name
- **Health Grade**: Filter by A, B, or C grades
- **Food Type**: Filter by cuisine type
- **Address**: Search by street address
- **Borough**: Filter by NYC borough (Manhattan, Brooklyn, Queens, Bronx, Staten Island)
- **Zip Code**: Search by specific zip code

### 🗺️ Interactive Map

- View restaurants on an interactive map
- Color-coded markers based on health grades (Green=A, Yellow=B, Red=C)
- Current location support
- Tap markers to view restaurant details

### 📱 Offline Capability

- All restaurant data stored locally using SwiftData
- Search and browse restaurants without internet connection
- Automatic daily data refresh at 4:00 AM

### 🏥 Health Grade Display

- Prominent display of health inspection grades
- Color-coded grade indicators
- Detailed inspection information
- Health scores and inspection dates

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

### Models

- `Restaurant`: Core data model with SwiftData
- `RestaurantResponse`: API response model

### Views

- `ContentView`: Main tab-based interface
- `RestaurantDetailView`: Detailed restaurant information
- `RestaurantMapView`: Interactive map view
- `SearchFiltersView`: Advanced search filters
- `RestaurantListItemView`: List item component

### ViewModels

- `SearchViewModel`: Handles search logic and filtering
- `RestaurantDataService`: Manages data fetching and storage
- `LocationManager`: Handles location services
- `BackgroundRefreshService`: Manages background data updates

## Data Source

The app fetches data from the official NYC Health Department:

- **Source**: https://a816-health.nyc.gov/ABCEatsRestaurants/#!/Search
- **API Endpoint**: https://a816-health.nyc.gov/ABCEatsRestaurants/api/restaurants

## Technical Requirements

- **iOS**: 17.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+
- **Frameworks**: SwiftUI, SwiftData, MapKit, CoreLocation, BackgroundTasks

## Setup Instructions

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd ABCEats
   ```

2. **Open in Xcode**

   ```bash
   open ABCEats.xcodeproj
   ```

3. **Configure Background Tasks**

   - The app is configured to refresh data daily at 4:00 AM
   - Background tasks are registered in `Info.plist`

4. **Location Permissions**

   - The app requests location access for map functionality
   - Permission description is configured in `Info.plist`

5. **Build and Run**
   - Select your target device or simulator
   - Press Cmd+R to build and run

## Development Notes

### Mock Data

For development and testing, the app uses `MockDataService` which provides sample restaurant data. To switch to live data:

1. Replace `MockDataService()` with `RestaurantDataService()` in `ContentView.swift`
2. Ensure the NYC Health API is accessible

### Background Refresh

The background refresh functionality is configured but may require additional setup for production:

- Background app refresh must be enabled in iOS Settings
- The app must be backgrounded for background tasks to execute

### Data Storage

- Uses SwiftData for local storage
- Automatic data persistence
- Efficient querying and filtering

## Privacy & Permissions

- **Location**: Used to show nearby restaurants on the map
- **Background Processing**: Used for daily data refresh
- **Network**: Used to fetch restaurant data from NYC Health API

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- NYC Health Department for providing the restaurant inspection data
- Apple for SwiftUI and SwiftData frameworks
- The iOS development community for best practices and guidance
