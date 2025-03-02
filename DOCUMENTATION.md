
## Getting Started

Simplicity is a cross-platform cryptocurrency wallet application that provides secure and intuitive management of your digital assets. This guide will walk you through the setup process and core functionality.

### Installation

#### Prerequisites

Before installing Simplicity, ensure you have:

- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable version)
- Platform-specific development tools:
  - Android: Android Studio and Android SDK
  - iOS: Xcode and CocoaPods
  - Desktop: Windows, macOS, or Linux development tools

#### Installation Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/simplicity.git
   cd simplicity
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## First Launch & Onboarding

1. When you first launch Simplicity, you'll be presented with an onboarding screen that introduces key features:
   - Secure wallet management
   - Send & receive functionality
   - QR code integration
   - Balance tracking

2. Follow the onboarding screens by pressing "Next" or skip directly to the setup process by tapping "Skip".

## Creating Your Wallet

### Setting a Password

1. After onboarding, you'll be directed to the password creation screen.
2. Create a secure password (minimum 6 characters).
3. Agree to the terms of service by checking the box.
4. The app securely stores your password using SharedPreferences.

### Wallet Creation

1. Once your password is set, the app will:
   - Show a loading indicator
   - Connect to the wallet service
   - Create a new wallet account using the `WalletClient().createAccount()` method
   - Generate and store your private and public keys

2. Your wallet credentials will be:
   - Stored securely on your device
   - Backed up locally in the accounts.json file

### Backup Your Recovery Phrase

1. The app will convert your private key to a mnemonic phrase using convertToMnemonic().
2. **Important**: Write down this recovery phrase and store it in a secure location. It's the only way to recover your wallet if you lose access to your device.

## Using the Wallet

### Security

- Your wallet is protected by the password you created
- You'll need to enter your password to access the wallet or perform transactions

### Wallet Features

1. **Sending Transactions**:
   - Enter recipient address (or scan QR code)
   - Specify amount
   - The app will sign the transaction with your private key
   - The `sendTransaction` function handles submission to the blockchain

2. **Receiving Cryptocurrency**:
   - Share your public address
   - Others can send you funds directly to this address

3. **Settings**:
   - Access settings to customize security, language, and notification preferences
   - Get help and support information

4. **Mining** (if available):
   - The app includes functionality for mining rewards through the ProcessCubit
   - Mining rewards are automatically added to your balance

## Advanced Features

### Node Management

- The app automatically connects to available blockchain nodes
- Nodes are managed through the `updateKnownNodes()` function
- If connection issues occur, the app will rotate through available nodes

### Cloudflared Integration

- For certain functions, the app can utilize Cloudflared
- Installation instructions are provided if needed

## Platform-Specific Considerations

### Mobile (Android/iOS)
- Native platform integration for enhanced security
- QR code scanning using device camera

### Desktop (Windows/macOS/Linux)
- Expanded interface for larger screens
- Local file storage for improved backup options

## Troubleshooting

If you encounter issues:
1. Check your internet connection
2. Verify your password is entered correctly
3. Ensure you have the latest version of the app
4. For persistent issues, access the Help & Support section in Settings

Remember to always keep your password and recovery phrase secure, as they provide access to your cryptocurrency assets.
