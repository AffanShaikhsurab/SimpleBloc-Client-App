# Simplicity

A cross-platform cryptocurrency wallet application built with Flutter.

## Overview

Simplicity is a clean, intuitive cryptocurrency wallet that enables users to securely manage their digital assets. The application provides essential wallet functionality including sending and receiving transactions, balance checking, and QR code scanning for simplified address input.

## Features

- **Secure Wallet Management**: Create and manage cryptocurrency wallets
- **Send & Receive**: Transfer crypto to other wallet addresses
- **QR Code Integration**: Scan QR codes for simplified transaction input
- **Balance Tracking**: View your current wallet balance
- **Cross-Platform Support**: Available on Android, iOS, Windows, macOS, and Linux

## Installation

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable version)
- Appropriate development environment for your target platform:
  - Android: Android Studio and Android SDK
  - iOS: Xcode and CocoaPods
  - Desktop: Relevant development tools for Windows, macOS, or Linux

### Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/simplicity.git
   cd simplicity
   ```
2. Get dependencies:

   ```bash
   flutter pub get
   ```
3. Run the app:

   ```bash
   flutter run
   ```

## Platform-Specific Build Instructions

### Android

```bash
flutter build apk
```

### iOS

```bash
flutter build ios
```

### Windows

```bash
flutter build windows
```

### macOS

```bash
flutter build macos
```

### Linux

```bash
flutter build linux
```

## Project Structure

- lib - Dart source code
  - `screens/` - UI screens including wallet and transaction interfaces
- `assets/` - Application images and assets
- android, ios, windows, macos, linux - Platform-specific code

## Technologies Used

- **Flutter**: UI framework
- **Dart**: Programming language
- **SharedPreferences**: Local data storage
- **QR Code Scanner**: For reading wallet addresses

## Contributing

Contributions to Simplicity are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing cross-platform framework
- Contributors to the open-source libraries used in this project
