import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';

class ContratosReportesListScreen extends StatefulWidget {
  const ContratosReportesListScreen({super.key});

  @override
  State<ContratosReportesListScreen> createState() =>
      _ContratosReportesListScreenState();
}

class _ContratosReportesListScreenState
    extends State<ContratosReportesListScreen> {
  List<Map<String, dynamic>> _reportes = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarReportes();

    // Configurar el scroll para cargar más reportes al llegar al final
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 500 &&
          !_isLoadingMore &&
          _currentPage < _totalPages) {
        _cargarMasReportes();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    setState(() => _loading = true);

    try {
      final response = await DatabaseHelper.obtenerContratosReportes(
        page: 1,
        search: _searchQuery,
      );

      SafeLogger.debug('Response', response); // Debug

      setState(() {
        // Manejar la estructura de respuesta correcta
        if (response['success'] == true && response['data'] is List) {
          _reportes = List<Map<String, dynamic>>.from(response['data']);
        } else {
          _reportes = response['data'] ?? [];
        }
        _totalPages = response['total_pages'] ?? 1;
        _currentPage = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar reportes: $e')));
    }
  }

  Future<void> _cargarMasReportes() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await DatabaseHelper.obtenerContratosReportes(
        page: nextPage,
        search: _searchQuery,
      );

      List<Map<String, dynamic>> nuevosReportes;
      if (response['success'] == true && response['data'] is List) {
        nuevosReportes = List<Map<String, dynamic>>.from(response['data']);
      } else {
        nuevosReportes = response['data'] ?? <Map<String, dynamic>>[];
      }

      if (nuevosReportes.isNotEmpty) {
        setState(() {
          _reportes.addAll(nuevosReportes);
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más reportes: $e')),
      );
    }
  }

  Future<void> _buscarReportes() async {
    await _cargarReportes();
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Correcto':
        return Colors.green;
      case 'No válido':
        return Colors.red;
      case 'Pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusIndicator(String? estado) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getEstadoColor(estado),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Contratos'),
        backgroundColor: const Color(0xFF6A6FAE),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar reportes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onChanged: (value) => _searchQuery = value,
                    onSubmitted: (_) => _buscarReportes(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _buscarReportes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A6FAE),
                  ),
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reportes.isEmpty
                ? const Center(child: Text('No se encontraron reportes'))
                : RefreshIndicator(
                    onRefresh: _cargarReportes,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _reportes.length +
                          (_currentPage < _totalPages ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Si llegamos al final y hay más páginas, mostramos un indicador de carga
                        if (index == _reportes.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final reporte = _reportes[index];
                        final fechaStr = reporte['FECHAHORA_INICIO'];
                        DateTime fecha;
                        try {
                          if (fechaStr is String) {
                            if (fechaStr.startsWith('Tue, ') ||
                                fechaStr.startsWith('Wed, ') ||
                                fechaStr.startsWith('Thu, ') ||
                                fechaStr.startsWith('Fri, ') ||
                                fechaStr.startsWith('Sat, ') ||
                                fechaStr.startsWith('Sun, ') ||
                                fechaStr.startsWith('Mon, ')) {
                              // RFC 1123 format: "Wed, 21 Oct 2015 07:28:00 GMT"
                              final cleanStr = fechaStr
                                  .replaceAll('GMT', '')
                                  .trim();
                              fecha = DateFormat(
                                'EEE, dd MMM yyyy HH:mm:ss',
                                'en_US',
                              ).parse(cleanStr);
                            } else {
                              fecha = DateTime.parse(fechaStr);
                            }
                          } else {
                            fecha = DateTime.now();
                          }
                        } catch (e) {
                          fecha = DateTime.now();
                          SafeLogger.error(
                            'Error al parsear fecha: ${fechaStr ?? 'null'}', e
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatusIndicator(
                                  reporte['Estado_Reporte'],
                                ),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yy').format(fecha)),
                              ],
                            ),
                            title: Text(
                              '${reporte['ID_REPORTE'] ?? 'Sin código'} - ${reporte['MAQUINA_TXT'] ?? reporte['maquina']?['nombre'] ?? 'Sin máquina'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${reporte['CONTRATO_TXT'] ?? reporte['contrato']?['nombre'] ?? 'Sin contrato'}',
                                ),
                                Text(
                                  'Hrs: ${reporte['HORAS_TRABAJADAS'] ?? 'N/A'} - ${reporte['Descripcion'] ?? 'Sin descripción'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Usuario: ${reporte['USUARIO_TXT'] ?? reporte['usuario']?['usuario'] ?? 'Sin usuario'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                // Aquí implementarás la navegación al detalle
                                _mostrarDetalleReporte(reporte);
                              },
                            ),
                            onTap: () {
                              // También puedes usar onTap para ir al detalle
                              _mostrarDetalleReporte(reporte);
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleReporte(Map<String, dynamic> reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reporte ${reporte['ID_REPORTE'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Maquina:', reporte['MAQUINA_TXT']),
              _buildInfoRow('Contrato:', reporte['CONTRATO_TXT']),
              _buildInfoRow('Obra:', reporte['OBRA_TXT']),
              _buildInfoRow('Cliente:', reporte['CLIENTE_TXT']),
              _buildInfoRow('Usuario:', reporte['USUARIO_TXT']),
              const Divider(height: 24),
              _buildInfoRow('Horometro inicial:', reporte['ODOMETRO_INICIAL']?.toString()),
              _buildInfoRow('Horometro final:', reporte['ODOMETRO_FINAL']?.toString()),
              _buildInfoRow('Horas trabajadas:', reporte['HORAS_TRABAJADAS']?.toString()),
              _buildInfoRow('Horas minimas:', reporte['HORAS_MINIMAS']?.toString()),
              const Divider(height: 24),
              _buildInfoRow('KM inicial:', reporte['KM_INICIO']?.toString()),
              _buildInfoRow('KM final:', reporte['KM_FINAL']?.toString()),
              _buildInfoRow('Kilometros:', reporte['KILOMETROS']?.toString()),
              const Divider(height: 24),
              _buildInfoRow('Trabajo realizado:', reporte['Descripcion']),
              _buildInfoRow('Estado:', reporte['Estado_Reporte']),
              if (reporte['Observaciones'] != null && reporte['Observaciones'].toString().isNotEmpty)
                _buildInfoRow('Observaciones:', reporte['Observaciones']),
              if (reporte['Reporte_Pane'] != null && reporte['Reporte_Pane'].toString().isNotEmpty)
                _buildInfoRow('Incidente:', reporte['Reporte_Pane']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
