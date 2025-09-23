#!/bin/bash

# Script de build para Vercel
echo "🔄 Iniciando build de Flutter Web..."

# Verificar Flutter
flutter --version

# Habilitar Flutter Web
flutter config --enable-web

# Limpiar cache
flutter clean

# Obtener dependencias
flutter pub get

# Build para web con renderer HTML (mejor compatibilidad)
flutter build web --release --web-renderer html --base-href "/"

echo "✅ Build completado. Archivos en build/web/"