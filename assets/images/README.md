# Logo de Harcha Maquinaria

## 📁 Ubicación de archivos

Para implementar correctamente el logo de la empresa, necesitas colocar los siguientes archivos:

### **Dentro de la aplicación:**
- `assets/images/logo.png` - Logo principal (cualquier tamaño, recomendado 512x512)

### **Para PWA (iconos de instalación):**
- `web/icons/Icon-192.png` - 192x192 píxeles
- `web/icons/Icon-512.png` - 512x512 píxeles
- `web/icons/Icon-maskable-192.png` - 192x192 píxeles (versión maskable)
- `web/icons/Icon-maskable-512.png` - 512x512 píxeles (versión maskable)

### **Favicon:**
- `web/favicon.png` - 32x32 o 64x64 píxeles

## 🎨 Especificaciones

### **Formato:** PNG con fondo transparente
### **Colores:** Logo original de la empresa
### **Versión maskable:** Puede tener un área segura de 80% del total

## 🔧 Después de agregar los archivos:

1. Ejecutar: `flutter pub get`
2. Hacer build: `flutter build web --release`
3. Probar localmente
4. Commit y push para deployment automático

## 💡 Uso en código:

```dart
// Logo simple
HarchaLogo(width: 100, height: 100)

// Logo con texto
HarchaLoginLogo()

// Logo para AppBar
HarchaAppBarLogo()
```