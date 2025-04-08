# Flutter Google Maps Integrator (maps_flutter)

A Flutter desktop application designed to automate the initial setup and integration of the `google_maps_flutter` package into existing Flutter projects. This tool streamlines the process of adding dependencies, configuring platform-specific files (Android & iOS), and injecting a basic demo map screen.

**(Note: This application itself is built with Flutter and is intended to be run on a development machine - Linux, macOS, or Windows - to modify *other* Flutter projects.)**

---

## Showcase / Screenshot


![Video](assets/video/flutter_google_maps_integrator.mp4)

---

## Features

*   **Project Selection:** Easily browse and select the target Flutter project directory using the system's file picker.
*   **Dependency Management:**
    *   Automatically adds the `google_maps_flutter` dependency to the target project's `pubspec.yaml`.
    *   Runs `flutter pub get` in the target project directory to fetch the new dependency.
*   **Android Configuration:**
    *   Locates the `AndroidManifest.xml` file.
    *   Adds or updates the necessary `<meta-data>` tag for the Google Maps API key within the `<application>` tag.
*   **iOS Configuration:**
    *   Detects whether the target project uses `AppDelegate.swift` (Swift) or `AppDelegate.m` (Objective-C).
    *   Adds the required `import GoogleMaps` / `#import <GoogleMaps/GoogleMaps.h>` statement.
    *   Injects or updates the `GMSServices.provideAPIKey("YOUR_API_KEY")` call within the `application:didFinishLaunchingWithOptions:` method.
*   **API Key Handling:**
    *   Prompts for your Google Maps API Key.
    *   Provides an option to **skip** API key configuration if it's already handled manually or through other means in the target project.
*   **Demo Code Injection:**
    *   Creates a new file `lib/map_demo_screen.dart` in the target project containing a basic `GoogleMap` widget implementation.
*   **User Interface & Feedback:**
    *   Provides a clear, step-by-step interface.
    *   Shows the currently selected project path.
    *   Displays progress indicators and status messages during the automation process.
    *   Shows a confirmation or error dialog upon completion.
*   **State Management:** Uses `flutter_riverpod` for clean state management within the tool itself.

---

## Prerequisites

Before using this tool, ensure you have:

1.  **Flutter SDK:** Installed and configured on your system.
2.  **Target Flutter Project:** An existing Flutter project where you want to integrate Google Maps.
3.  **Google Maps API Key:** You need API keys enabled for both the "Maps SDK for Android" and "Maps SDK for iOS". You can obtain these from the [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/). (This is only required if you are *not* using the "Skip API Key Configuration" option).
4.  **Desktop Development Enabled (for Flutter):** If you haven't run Flutter desktop apps before, you might need to enable support (e.g., `flutter config --enable-windows-desktop`).

---

## How to Use

1.  **Clone or Download:** Get the code for *this* project (`maps_flutter`).
    ```bash
    git clone git@github.com:RotRot-pi/flutter_google_maps_integrator.git
    cd maps_flutter
    ```
2.  **Get Dependencies (for this tool):**
    ```bash
    flutter pub get
    ```
3.  **Run the Application:** Launch the Flutter Google Maps Integrator tool. Replace `windows` with `macos` or `linux` based on your OS.
    ```bash
    flutter run -d windows
    # or
    # flutter run -d macos
    # or
    # flutter run -d linux
    ```
4.  **Step 1: Select Project:** Click the "Select Flutter Project Directory" button and choose the root directory of the Flutter project you want to modify. Ensure it contains a `pubspec.yaml` file.
5.  **Step 2: Enter API Key (or Skip):**
    *   Enter your Google Maps API Key in the provided field.
    *   OR, check the "Skip API Key Configuration" box if you've already set up the keys in your target project or will do it manually later.
6.  **Step 3: Run Integration:** Click the "Start Integration Process" button.
7.  **Monitor Progress:** Observe the status messages and progress bar. The tool will perform the steps outlined in the "Features" section.
8.  **Check Results:** A dialog will appear indicating success or failure.
9.  **Manual Step (Required for Demo):**
    *   The tool creates `lib/map_demo_screen.dart` in your target project but **does not** modify your `lib/main.dart`.
    *   To see the injected demo map, **manually edit your target project's `lib/main.dart`**:
        *   **Add the import:**
            ```dart
            import 'map_demo_screen.dart'; // Add this near other imports
            ```
        *   **Change the `home` property** in your `MaterialApp` widget:
            ```dart
            // Find this line (or similar):
            // home: const MyHomePage(title: 'Flutter Demo Home Page'),
            // And change it to:
            home: const MapDemoScreen(),
            ```
10. **Run Target Project:** Run your *target* Flutter project on an emulator or device to see the Google Map.

---

## How It Works (Automation Steps)

The tool executes the following sequence when "Start Integration Process" is clicked:

1.  **Validation:** Checks if a project path is selected and if an API key is provided (or skipped).
2.  **Add Dependency:** Modifies the target `pubspec.yaml` to include `google_maps_flutter`.
3.  **Run Pub Get:** Executes `flutter pub get` in the target project's directory.
4.  **Configure Android:** Parses `AndroidManifest.xml` and adds/updates the API key metadata.
5.  **Configure iOS:** Parses `AppDelegate.swift` or `AppDelegate.m` and adds/updates the import and API key initialization code. (Steps 4 & 5 are skipped if the checkbox is ticked).
6.  **Inject Demo Code:** Creates the `lib/map_demo_screen.dart` file in the target project.
7.  **Report Status:** Displays a success or error message.

---

## Important Notes & Caveats


*   **Backup Recommended:** While the tool tries to be careful, it's always wise to **back up your target project** or use version control (like Git) before running any automation script that modifies files.
*   **File Parsing:** The tool relies on finding specific patterns and structures in `AndroidManifest.xml` and `AppDelegate` files. Highly customized or unusual project structures might cause the configuration steps to fail. Check the tool's log output and the modified files if issues occur.
*   **Error Handling:** Basic error handling is included, but edge cases might exist. If an error occurs, the process stops, and an error message is displayed.
*   **API Key Security:** Remember that API keys embedded directly in `AndroidManifest.xml` and `AppDelegate` are not the most secure method for production apps. Consider using environment variables or other secure key management techniques for released applications. This tool focuses on simplifying the initial *setup*.

---

## Contributing

Contributions are welcome! If you find bugs or have ideas for improvements, please open an issue or submit a pull request.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details (assuming you have an MIT license file).