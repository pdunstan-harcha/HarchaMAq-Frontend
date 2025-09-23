
# HarchaMAq Frontend 📱

> Flutter mobile application for Harcha Maquinaria management system

## 🚀 Overview

Este es el frontend para la gestión de maquinaria HarchaMAq, construido en Flutter. Permite administrar operaciones, recargas de combustible, contratos y reportes.

## ✨ Features

- **🔐 Autenticación de usuario**
- **📊 Dashboard**
- **⛽ Gestión de combustible**
- **📝 Contratos y reportes**
- **📋 Registros de entradas/salidas**
- **🔄 Sincronización en tiempo real**
- **📱 Multi-plataforma: Android, iOS, Web**

## 🛠️ Tech Stack

- **Framework**: Flutter 3.8.0+
- **Lenguaje**: Dart
- **State Management**: Provider
- **HTTP Client**: http
- **Storage**: flutter_secure_storage
- **Logging**: SafeLogger + logger
- **Deployment**: Vercel (Web)

## 📦 Dependencias

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

## 🚀 Instalación y Configuración

### Prerequisitos

- Flutter SDK 3.8.0+
- Dart SDK
- Android Studio / VS Code
- Git

### Pasos de instalación

1. **Clonar el repositorio**

   ```bash
   git clone https://github.com/panchoxgrande/HarchaMAq-Frontend.git
   cd HarchaMAq-Frontend
   ```

2. **Instalar dependencias**

   ```bash
   flutter pub get
   ```

3. **Configurar entorno**

   ```bash
   cp .env.example .env
   # Edita .env con tu URL de backend
   ```

4. **Ejecutar la app**

   ```bash
   # Android/iOS
   flutter run
   # Web
   flutter run -d chrome
   ```

## 🏗️ Comandos útiles

### Desarrollo local

```bash
flutter run -d chrome
flutter run -d web-server --web-port 3000
```

### Build para producción

```bash
flutter build web --release
flutter build web --release --web-renderer html
flutter build web --release --base-href /tu-proyecto/
```

### Variables de entorno

```bash
flutter build web --release --dart-define=BASE_URL=https://harchaback-production.up.railway.app
```

### Vercel CLI

```bash
npm i -g vercel
vercel login
vercel --prod
```

## 🌐 Deployment (Vercel)

1. **Build para web**

   ```bash
   flutter build web --release
   ```

2. **Subir a GitHub**
3. **Conectar repo en Vercel**
4. **Configurar build settings** (vercel.json)
5. **Deploy automático**

### Guía rápida

1. Limpiar y verificar web:

   ```bash
   flutter clean
   flutter pub get
   flutter build web --release --web-renderer html
   ```

2. Subir a GitHub:

   ```bash
   git add .
   git commit -m "feat: configurar para deployment en Vercel"
   git push origin main
   ```

3. Configurar en Vercel:
   - Framework: Other
   - Root Directory: ./
   - Build Command: vercel.json
   - Output Directory: build/web
   - Install Command: flutter pub get

## 🐙 Setup GitHub

1. Crear repo en GitHub
2. No agregar README ni .gitignore (ya existen)
3. Conectar repo local:

   ```powershell
   git branch -M main
   git remote add origin https://github.com/panchoxgrande/NOMBRE-DEL-REPO.git
   git push -u origin main
   ```

4. Configurar credenciales si es necesario:

   ```powershell
   git config --global user.name "Tu Nombre"
   git config --global user.email "tu-email@gmail.com"
   ```

## 📖 Logging System

Importa y usa SafeLogger:

```dart
import '../utils/logger.dart';
SafeLogger.info('Usuario autenticado correctamente');
SafeLogger.debug('Datos recibidos', responseData);
SafeLogger.warning('Conexión lenta detectada');
SafeLogger.error('Error al procesar datos', e);
```

## 📁 Estructura del Proyecto

```text
lib/
├── config.dart              # Configuración
├── main.dart                # Entry point
├── providers/               # State management
├── screens/                 # UI
├── services/                # API y storage
├── utils/                   # Utilidades (logger, etc.)
└── examples/                # Ejemplos
```

## 🧪 Pruebas

```bash
flutter test
flutter drive --target=test_driver/app.dart
```

## 🤝 Contribuir

1. Forkea el repo
2. Crea tu branch (`git checkout -b feature/nueva-feature`)
3. Commit (`git commit -m 'Agrega nueva feature'`)
4. Push (`git push origin feature/nueva-feature`)
5. Abre un Pull Request

## 📄 Licencia

Software propietario para Harcha Maquinaria.

## 🆘 Soporte

- Crea un issue en GitHub
- Contacta al equipo de desarrollo

## 🏗️ Estado del desarrollo

- ✅ Autenticación
- ✅ Dashboard
- ✅ Gestión de combustible
- ✅ Logging
- ✅ Web deployment
- 🚧 Reportes avanzados (en progreso)
- 📋 Push notifications (pendiente)

---

**Desarrollado con ❤️ por el equipo HarchaMAq**

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