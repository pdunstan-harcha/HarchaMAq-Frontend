# 🚀 Guía de Deployment en Vercel

## 📋 Pre-requisitos

1. **Cuenta en Vercel**: [vercel.com](https://vercel.com)
2. **Flutter Web habilitado**: `flutter config --enable-web`
3. **Git repository** con tu código

## 🔧 Pasos para deployar

### 1. Preparar el proyecto localmente

```bash
# Limpiar y verificar que funciona en web
flutter clean
flutter pub get
flutter build web --release --web-renderer html
```

### 2. Subir a GitHub/GitLab

```bash
git add .
git commit -m "feat: configurar para deployment en Vercel"
git push origin main
```

### 3. Configurar en Vercel

1. **Ir a [vercel.com](https://vercel.com)** y hacer login
2. **Click en "New Project"**
3. **Importar tu repositorio** de GitHub/GitLab
4. **Configurar el proyecto**:
   - **Framework Preset**: Other
   - **Root Directory**: `./` (o `./frontend` si está en subdirectorio)
   - **Build Command**: Se lee desde `vercel.json`
   - **Output Directory**: `build/web`
   - **Install Command**: `flutter pub get`

### 4. Variables de entorno en Vercel

En el dashboard de Vercel:
1. **Project Settings > Environment Variables**
2. **Agregar variables**:
   ```
   Name: BASE_URL
   Value: https://tu-backend-api.com
   Environment: Production, Preview, Development
   ```

### 5. Deploy automático

¡Listo! Vercel deployará automáticamente:
- ✅ En cada push a `main`
- ✅ Preview en cada PR
- ✅ Con HTTPS automático
- ✅ CDN global

## 🌐 URLs resultantes

- **Producción**: `https://tu-proyecto.vercel.app`
- **Preview**: `https://tu-proyecto-git-branch.vercel.app`

## ⚙️ Configuración avanzada

### Custom Domain
1. **Project Settings > Domains**
2. **Add Domain**: `tudominio.com`
3. **Configurar DNS** según instrucciones

### Analytics
- **Project Settings > Analytics** para métricas

### Edge Functions (si necesitas backend)
- Crear archivos en `/api/` para serverless functions

## 🔍 Troubleshooting

### Error de rutas
- ✅ Verificar `vercel.json` tiene rewrites configurados
- ✅ Usar `--base-href /` en build command

### Error de CORS
- ✅ Configurar CORS en tu backend
- ✅ Usar la URL correcta en variables de entorno

### Performance
- ✅ Usar `--web-renderer html` para mejor compatibilidad
- ✅ Configurar cache headers en `vercel.json`

## 📱 Consideraciones Flutter Web

1. **PWA**: Tu app funcionará como Progressive Web App
2. **Mobile**: Responsive design es importante
3. **Performance**: Considera lazy loading para rutas
4. **Storage**: `flutter_secure_storage` funciona en web
5. **Plugins**: Verificar compatibilidad web de plugins

## 🔐 Seguridad

- ✅ HTTPS automático por Vercel
- ✅ Headers de seguridad en `vercel.json`
- ✅ Variables de entorno seguras
- ✅ No hardcodear APIs keys

¡Tu app Flutter estará live en minutos! 🎉