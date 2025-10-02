import 'package:android_intent_plus/android_intent.dart';
import 'package:html_to_image_flutter/html_to_image_flutter.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:harcha_maquinaria/services/database_helper.dart';
import 'dart:typed_data';
import 'dart:io';

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

  Future<void> imprimirReciboComoImagen(BuildContext context, String htmlRecibo) async {
    try {
      final screenshotController = ScreenshotController();

      // Renderiza el HTML como widget y captura como imagen
      final imageBytes = await screenshotController.captureFromWidget(
        Material(
          child: Container(
            width: 300,
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: HtmlWidget(htmlRecibo),
          ),
        ),
        pixelRatio: 2.0,
      );

      // Guarda la imagen
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/recibo.png');
      await file.writeAsBytes(imageBytes);

      // Envía a RawBT
      final intent = AndroidIntent(
        action: 'android.intent.action.SEND',
        package: 'ru.a402d.rawbtprinter',
        type: 'image/png',
        arguments: <String, dynamic>{
          'android.intent.extra.STREAM': file.uri.toString(),
        },
      );
      await intent.launch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir recibo: $e')),
      );
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
                                        imprimirReciboComoImagen(context, htmlRecibo);
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
