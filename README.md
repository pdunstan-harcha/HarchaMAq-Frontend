# HarchaMAq Frontend 📱

> Flutter mobile application for Harcha Maquinaria management system

## 🚀 Overview

This is the frontend application for HarchaMAq, a machinery management system built with Flutter. The app allows users to manage machinery operations, fuel recharges, contracts, and reports.

## ✨ Features

- **🔐 User Authentication** - Secure login system
- **📊 Dashboard** - Overview of operations and statistics  
- **⛽ Fuel Management** - Record and track fuel recharges
- **📝 Contracts & Reports** - Manage contracts and generate reports
- **📋 Entry/Exit Logs** - Track machinery entries and exits
- **🔄 Real-time Sync** - Sync with backend API
- **📱 Multi-platform** - Android, iOS, Web support

## 🛠️ Tech Stack

- **Framework**: Flutter 3.8.0+
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: http package
- **Storage**: flutter_secure_storage
- **Logging**: Custom SafeLogger with logger package
- **Deployment**: Vercel (Web)

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.18.1
  image_picker: ^1.0.4 
  logger: ^2.6.1
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.0 or higher
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/panchoxgrande/HarchaMAq-Frontend.git
   cd HarchaMAq-Frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your backend URL
   ```

4. **Run the app**
   ```bash
   # For Android/iOS
   flutter run
   
   # For Web
   flutter run -d chrome
   ```

## 🔧 Configuration

### Environment Variables

Create a `.env` file or use `--dart-define`:

```bash
flutter run --dart-define=BASE_URL=https://your-backend-api.com
```

### Backend Configuration

Update `lib/config.dart` with your backend URL:

```dart
static const String prodUrl = 'https://your-api-url.com';
```

## 🌐 Deployment

### Web (Vercel)

1. **Build for web**
   ```bash
   flutter build web --release
   ```

2. **Deploy to Vercel**
   - Push to GitHub
   - Connect repository in Vercel
   - Configure build settings (already in `vercel.json`)
   - Deploy automatically

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

## 📖 Documentation

- [📋 Deployment Guide](DEPLOYMENT.md) - Complete Vercel deployment instructions
- [🐛 Logging System](LOGGING.md) - SafeLogger usage and configuration
- [⚡ Commands Reference](COMMANDS.md) - Useful Flutter and deployment commands

## 🧪 Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📁 Project Structure

```
lib/
├── config.dart              # App configuration
├── main.dart                 # App entry point
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # API and storage services
├── utils/                    # Utilities (logger, etc.)
└── examples/                 # Code examples
```

## 🔍 Key Features

### Logging System
Uses custom `SafeLogger` with the `logger` package:
```dart
SafeLogger.info('User logged in successfully');
SafeLogger.error('API error', error);
SafeLogger.debug('Response data', responseData);
```

### API Integration
RESTful API integration with automatic token management:
```dart
final response = await ApiClient().get('/endpoint');
```

### Secure Storage
Encrypted local storage for sensitive data:
```dart
await SecureStorage.store('token', userToken);
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software for Harcha Maquinaria.

## 🆘 Support

For support and questions:
- Create an issue in GitHub
- Contact the development team

## 🏗️ Development Status

- ✅ **Authentication System** - Complete
- ✅ **Dashboard** - Complete  
- ✅ **Fuel Management** - Complete
- ✅ **Logging System** - Complete
- ✅ **Web Deployment** - Complete
- 🚧 **Advanced Reports** - In Progress
- 📋 **Push Notifications** - Planned

---

**Built with ❤️ by the HarchaMAq Team**