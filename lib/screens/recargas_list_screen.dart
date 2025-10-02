import 'dart:convert' show base64, utf8;
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:harcha_maquinaria/services/database_helper.dart';
import 'package:harcha_maquinaria/utils/platform_helper.dart';
import 'package:harcha_maquinaria/utils/html_to_escpos.dart';
import 'package:url_launcher/url_launcher.dart';

class RecargasListScreen extends StatefulWidget {
  const RecargasListScreen({super.key});

  @override
  State<RecargasListScreen> createState() => _RecargasListScreenState();
}

class _RecargasListScreenState extends State<RecargasListScreen> {
  List<Map<String, dynamic>> _recargas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarRecargas();
  }

  Future<void> _cargarRecargas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final recargas = await DatabaseHelper.obtenerRecargasCombustible();

      setState(() {
        _recargas = recargas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _mostrarDetalleRecarga(Map<String, dynamic> recarga) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Recarga: ${recarga['codigo'] ?? 'N/A'}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(
                    'Máquina:', recarga['maquina']?['nombre'] ?? 'N/A'),
                _buildInfoRow(
                    'Usuario:', recarga['usuario']?['usuario'] ?? 'N/A'),
                if (recarga['operador']?['usuario'] != null &&
                    recarga['operador']['usuario'].toString().isNotEmpty)
                  _buildInfoRow('Operador:', recarga['operador']['usuario']),
                if (recarga['rut_operador'] != null &&
                    recarga['rut_operador'].toString().isNotEmpty)
                  _buildInfoRow('RUT Operador:', recarga['rut_operador']),
                _buildInfoRow(
                    'Fecha:',
                    _formatearFecha(
                        recarga['fecha'] ?? recarga['fechahora_recarga'])),
                _buildInfoRow('Litros:', '${recarga['litros'] ?? 0} L'),
                if (recarga['odometro'] != null)
                  _buildInfoRow('Odómetro:', '${recarga['odometro']} Hr'),
                if (recarga['kilometros'] != null)
                  _buildInfoRow('Kilómetros:', '${recarga['kilometros']} km'),
                if (recarga['patente'] != null &&
                    recarga['patente'].toString().isNotEmpty)
                  _buildInfoRow('Patente:', recarga['patente']),
                if (recarga['obra'] != null)
                  _buildInfoRow('Obra:', recarga['obra']?['nombre'] ?? 'N/A'),
                if (recarga['cliente'] != null)
                  _buildInfoRow(
                      'Cliente:', recarga['cliente']?['nombre'] ?? 'N/A'),
                if (recarga['observaciones'] != null &&
                    recarga['observaciones'].toString().isNotEmpty)
                  _buildInfoRow('Observaciones:', recarga['observaciones']),
                // Mostrar datos de recarga anterior si existen
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';

    try {
      if (fecha is String) {
        final dateTime = DateTime.parse(fecha);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
            '${dateTime.hour.toString().padLeft(2, '0')}:'
            '${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return fecha.toString();
    } catch (e) {
      return fecha.toString();
    }
  }

  Future<void> imprimirReciboRawBT(BuildContext context, String htmlRecibo) async {
    try {
      print('=== DEBUG IMPRESIÓN ===');
      print('isWeb: ${PlatformHelper.isWeb}');
      print('Plataforma: ${PlatformHelper.platformName}');
      print('Longitud HTML: ${htmlRecibo.length}');
      print('Primeros 200 caracteres: ${htmlRecibo.substring(0, htmlRecibo.length < 200 ? htmlRecibo.length : 200)}');

      // Convertir HTML a comandos ESC/POS
      print('Convirtiendo HTML a ESC/POS...');
      final escPosText = HtmlToEscPos.convertHtmlToEscPos(htmlRecibo);
      final escPosBase64 = HtmlToEscPos.toBase64(escPosText);

      print('ESC/POS generado (primeros 200 chars): ${escPosText.substring(0, escPosText.length < 200 ? escPosText.length : 200)}');

      // HTML original en base64
      final bytes = utf8.encode(htmlRecibo);
      final htmlBase64 = base64.encode(bytes);

      // Intent URI para RawBT con HTML
      final intentUri = 'intent:#Intent;'
          'action=android.intent.action.SEND;'
          'type=text/html;'
          'package=ru.a402d.rawbtprinter;'
          'S.android.intent.extra.TEXT=${Uri.encodeComponent(htmlRecibo)};'
          'end';

      // URI con comandos ESC/POS (RECOMENDADO)
      final escPosUri = 'rawbt:base64,$escPosBase64';

      // URI con HTML crudo
      final htmlRawUri = 'rawbt:base64,$htmlBase64';

      print('HTML Base64 longitud: ${htmlBase64.length}');
      print('ESC/POS Base64 longitud: ${escPosBase64.length}');
      print('Intent URI (primeros 150 chars): ${intentUri.substring(0, intentUri.length < 150 ? intentUri.length : 150)}');
      print('ESC/POS URI (primeros 100 chars): ${escPosUri.substring(0, escPosUri.length < 100 ? escPosUri.length : 100)}');

      // Mostrar diálogo de debug con opciones
      if (context.mounted) {
        final result = await showDialog<String>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Debug - Imprimir'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Plataforma: ${PlatformHelper.platformName}'),
                    Text('Longitud HTML: ${htmlRecibo.length} bytes'),
                    Text('ESC/POS Base64: ${escPosBase64.length} bytes'),
                    Text('HTML Base64: ${htmlBase64.length} bytes'),
                    const SizedBox(height: 10),
                    const Text('Preview HTML:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        htmlRecibo.substring(0, htmlRecibo.length < 300 ? htmlRecibo.length : 300),
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('cancel'),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('print_escpos'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                  ),
                  child: const Text('✓ ESC/POS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('print_html_intent'),
                  child: const Text('HTML Intent'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('print_html_raw'),
                  child: const Text('HTML Raw'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('browser'),
                  child: const Text('Ver'),
                ),
              ],
            );
          },
        );

        print('Opción seleccionada: $result');

        if (result == 'print_escpos') {
          // RECOMENDADO: Usar ESC/POS
          await _enviarARawBT(context, escPosUri, htmlRecibo, modo: 'ESC/POS');
        } else if (result == 'print_html_intent') {
          // Intentar con Intent SEND
          await _enviarARawBT(context, intentUri, htmlRecibo, modo: 'HTML Intent');
        } else if (result == 'print_html_raw') {
          // HTML como datos crudos
          await _enviarARawBT(context, htmlRawUri, htmlRecibo, modo: 'HTML Raw');
        } else if (result == 'browser') {
          await _abrirEnNavegador(context, htmlRecibo);
        }
      }
    } catch (e, stackTrace) {
      print('ERROR en imprimirReciboRawBT: $e');
      print('StackTrace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver detalles',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error detallado'),
                    content: SingleChildScrollView(
                      child: Text('Error: $e\n\nStack trace:\n$stackTrace'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _enviarARawBT(BuildContext context, String uri, String htmlRecibo, {required String modo}) async {
    try {
      print('Intentando abrir RawBT...');
      print('Modo: $modo');

      if (PlatformHelper.isWeb) {
        // Para PWA: usar url_launcher que funciona en web
        print('Usando url_launcher para PWA');
        final parsedUri = Uri.parse(uri);
        final launched = await launchUrl(
          parsedUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('RawBT lanzado exitosamente desde PWA');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Abriendo RawBT en modo $modo...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print('No se pudo lanzar RawBT desde PWA');
          throw Exception('No se pudo abrir RawBT. Asegúrate de que esté instalado.');
        }
      } else {
        // Para Android nativo: usar AndroidIntent
        print('Usando AndroidIntent para Android nativo');

        if (modo == 'HTML Intent') {
          // Usar Intent SEND para HTML
          final intent = AndroidIntent(
            action: 'android.intent.action.SEND',
            type: 'text/html',
            package: 'ru.a402d.rawbtprinter',
            arguments: {'android.intent.extra.TEXT': htmlRecibo},
          );
          await intent.launch();
        } else {
          // Usar esquema rawbt: para datos RAW o ESC/POS
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: uri,
          );
          await intent.launch();
        }

        print('AndroidIntent lanzado exitosamente');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Intent enviado a RawBT en modo $modo'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al enviar a RawBT: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir RawBT: $e\n\nIntenta con el otro modo o "Ver HTML".'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _abrirEnNavegador(BuildContext context, String htmlRecibo) async {
    try {
      print('Abriendo HTML en navegador...');
      final dataUri = 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlRecibo)}';

      if (PlatformHelper.isWeb) {
        // Para PWA
        final uri = Uri.parse(dataUri);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Para Android nativo
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: dataUri,
          type: 'text/html',
        );
        await intent.launch();
      }

      print('HTML abierto en navegador');
    } catch (e) {
      print('Error al abrir en navegador: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir navegador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recargas de Combustible'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarRecargas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar datos',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarRecargas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _recargas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_gas_station_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay recargas registradas',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarRecargas,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _recargas.length,
                        itemBuilder: (context, index) {
                          final recarga = _recargas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF1E3A8A),
                                child: Icon(
                                  Icons.local_gas_station,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                recarga['codigo'] ??
                                    recarga['ID_RECARGA'] ??
                                    'Sin código',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Máquina: ${recarga['maquina']?['nombre'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Litros: ${recarga['litros'] ?? recarga['LITROS']} L - ${_formatearFecha(recarga['fecha'] ?? recarga['FECHA'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.print, color: Colors.blue),
                                    tooltip: 'Imprimir recibo',
                                    onPressed: () async {
                                      try {
                                        final htmlRecibo = await DatabaseHelper.obtenerReciboRecargaHtml(recarga['id']);
                                        await imprimirReciboRawBT(context, htmlRecibo);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al obtener recibo: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                              onTap: () => _mostrarDetalleRecarga(recarga),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
