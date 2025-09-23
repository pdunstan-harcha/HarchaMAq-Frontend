# Comandos útiles para Flutter Web y Vercel

## 🏗️ Build Commands

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

### Con variables de entorno
```bash
flutter build web --release --dart-define=BASE_URL=https://api.produccion.com
```

## 🚀 Vercel Commands

### CLI de Vercel (opcional)
```bash
npm i -g vercel
vercel login
vercel --prod
```

### Deployment manual
```bash
# Build local
flutter build web --release

# Subir a Vercel (si tienes CLI)
vercel --prod
```

## 🧪 Testing

### Test local de la build
```bash
flutter build web --release
cd build/web
python -m http.server 8000
# Abrir http://localhost:8000
```

### Con servidor Node.js
```bash
npx serve -s build/web -p 3000
```

## 🔧 Troubleshooting

### Limpiar cache
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Verificar Flutter Web
```bash
flutter config --enable-web
flutter devices
```

### Ver logs en Vercel
- Dashboard > Project > Functions tab
- O usar `vercel logs`

## 📱 URLs importantes

- **Local dev**: http://localhost:3000
- **Vercel preview**: https://proyecto-git-branch.vercel.app  
- **Vercel prod**: https://proyecto.vercel.app
- **Backend**: Configurar en variables de entorno

¡Happy deployment! 🎉