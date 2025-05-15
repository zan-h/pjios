# PhoneJail

An iOS app that helps users manage their screen time and app usage through an engaging LLM-based "jailkeeper" system. Users must convince an AI jailkeeper to grant them access to blocked apps, making the process of app access more mindful and intentional.

## Features

-   App blocking and management using iOS ScreenTime API
-   AI-powered "jailkeeper" that users must convince to access blocked apps
-   Customizable app blocking lists
-   App usage statistics and insights
-   Multiple jailkeeper personalities
-   Secure and private conversation handling

## Requirements

-   iOS 15.0+
-   Xcode 14.0+
-   Swift 5.7+
-   Active Apple Developer Account (for ScreenTime API access)

## Project Structure

phonejailOS/
├── App/
│ ├── AppDelegate.swift # Application delegate.
│ ├── SceneDelegate.swift # Scene delegate for managing app scenes.
│ └── Environment/
│ └── AppEnvironment.swift # Manages app environment settings.
│
├── Coordinators/
│ ├── AppCoordinator.swift # Main app coordinator.
│ └── Modules/
│ ├── MainCoordinator.swift # Main app flow coordinator.
│ ├── ProfileCoordinator.swift # Profile management flow.
│ └── SettingsCoordinator.swift # Settings and preferences flow.
│
├── Modules/
│ ├── Main/
│ │ ├── View/ # Main app features views.
│ │ ├── ViewModel/ # Main app view models.
│ │ ├── Model/ # Main app models.
│ │ └── Service/ # Main app services.
│ │
│ ├── Settings/
│ │ ├── View/ # App settings views.
│ │ ├── ViewModel/ # App settings view models.
│ │ ├── Model/ # App settings models.
│ │ └── Service/ # App settings services.
│
├── Services/
│ ├── API/
│ │ ├── APIClient.swift # API client for network requests (if needed, potentially not).
│ │ └── Endpoints.swift # API endpoints configuration (if needed, potentially not).
│ │
│ └── Persistence/
│ ├── CoreDataStack.swift # Core Data setup for local database.
│ └── LocalStorage.swift # User defaults or file-based storage.
│ │
│ └── LLM/
│ ├── CoreLLMIntegration.swift # Generic LLM initialisation for the app.
│ ├── LLMClient.swift # LLM client for the app to handle llm interaction.
│ └── LLM.swift # The LLM we are using
│
├── Helpers/
│ ├── FormatterHelper.swift # Utility for formatting dates, numbers, etc.
│ ├── Validator.swift # Input validation functions.
│
├── Components/
│ ├── Common/
│ │ ├── CustomButton.swift # Reusable button component.
│ │ └── CustomLabel.swift # Reusable label component.
│ │
│ └── ReusableViews/
│ └── CardView.swift # Reusable card view component.
│
├── Resources/
│ ├── Assets.xcassets # Image assets (icons, illustrations, etc.).
│ ├── Localizable.strings # Localization strings for multiple languages.
│ └── Fonts/ # Custom fonts used in the app.
│
├── Extensions/
│ ├── UIView+Ext.swift # Extensions for UIView.
│ ├── String+Ext.swift # Extensions for String.
│ └── UIColor+Ext.swift # Extensions for UIColor.
│
├── Protocols/
│ ├── Coordinatable.swift # Protocol for coordinator pattern.
│ └── Reusable.swift # Protocol for reusable UI components.
│
├── Utils/
│ ├── Logger.swift # Custom logging utility.
│ └── NetworkMonitor.swift # Network connectivity monitor.
│
└── Tests/
├── Unit/ # Unit tests for core logic and services.
└── UI/ # UI tests for user interface.

## Setup

1. Clone the repository
2. Open `phonejailOS.xcodeproj` in Xcode
3. Install dependencies (if any)
4. Build and run the project

## Development

-   Follow MVVM architecture pattern
-   Use SwiftUI for UI development
-   Implement unit tests for new features
-   Follow Swift style guide

## Testing

-   Unit tests are located in `phonejailOSTests/`
-   UI tests are located in `phonejailOSUITests/`

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

[License details to be added]

## Contact

[Contact information to be added]
