import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:harcha_maquinaria/services/database_helper.dart';

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
      print('Longitud HTML: ${htmlRecibo.length}');
      print('Primeros 200 caracteres: ${htmlRecibo.substring(0, htmlRecibo.length < 200 ? htmlRecibo.length : 200)}');

      // RawBT acepta HTML directamente mediante esquema URI
      // Formato: rawbt:base64
      final encoded = Uri.encodeComponent(htmlRecibo);
      final rawbtUri = 'rawbt:base64,$encoded';

      print('URI generada (primeros 100 chars): ${rawbtUri.substring(0, rawbtUri.length < 100 ? rawbtUri.length : 100)}');
      print('Longitud URI: ${rawbtUri.length}');

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
                    Text('Longitud HTML: ${htmlRecibo.length}'),
                    Text('Longitud URI: ${rawbtUri.length}'),
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
                  onPressed: () => Navigator.of(dialogContext).pop('print'),
                  child: const Text('Imprimir con RawBT'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('browser'),
                  child: const Text('Abrir en navegador'),
                ),
              ],
            );
          },
        );

        print('Opción seleccionada: $result');

        if (result == 'print') {
          // Para Android nativo, usa AndroidIntent
          print('Intentando lanzar AndroidIntent...');
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: rawbtUri,
          );
          await intent.launch();
          print('AndroidIntent lanzado exitosamente');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Intent enviado a RawBT'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (result == 'browser') {
          // Abrir HTML en navegador para debug
          print('Abriendo en navegador...');
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlRecibo)}',
            type: 'text/html',
          );
          await intent.launch();
          print('HTML abierto en navegador');
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
