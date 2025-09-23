import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar el logo de Harcha Constructora
class HarchaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final bool useOriginalColors;

  const HarchaLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.showText = false,
    this.useOriginalColors = true,
  });

  // Colores oficiales de Harcha Constructora
  static const Color harchaBlue = Color(0xFF0066CC);
  static const Color harchaGray = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image
        Image.asset(
          'assets/images/logo.png',
          width: width ?? 120,
          height: height ?? 120,
          color: useOriginalColors ? null : color,
          errorBuilder: (context, error, stackTrace) {
            // Fallback si no se encuentra la imagen
            return Container(
              width: width ?? 120,
              height: height ?? 120,
              decoration: BoxDecoration(
                color: harchaBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: (width ?? 120) * 0.4,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HARCHA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (width ?? 120) * 0.12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Texto opcional
        if (showText) ...[
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'HARCHA\n',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: useOriginalColors ? harchaBlue : (color ?? harchaBlue),
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: 'constructora',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: useOriginalColors ? harchaGray : (color ?? harchaGray),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget para el logo en el AppBar
class HarchaAppBarLogo extends StatelessWidget {
  const HarchaAppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const HarchaLogo(
      width: 40,
      height: 40,
      color: Colors.white,
    );
  }
}

/// Widget para pantalla de login/splash
class HarchaLoginLogo extends StatelessWidget {
  const HarchaLoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const HarchaLogo(
      width: 150,
      height: 150,
      showText: true,
    );
  }
}