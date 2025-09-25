import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';
import 'registro_screen.dart';

enum Orden { fechaDesc, fechaAsc, ingresoPrimero, salidaPrimero }

class IngresosSalidasListScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;
  const IngresosSalidasListScreen(
      {super.key, required this.usuarioId, this.usuarioNombre = ''});

  @override
  _IngresosSalidasListScreenState createState() =>
      _IngresosSalidasListScreenState();
}

class _IngresosSalidasListScreenState extends State<IngresosSalidasListScreen> {
  List<dynamic> registros = [];
  bool isLoading = true;
  Orden ordenActual = Orden.fechaDesc;

  // Variables para paginación
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  bool hasNextPage = false;
  bool hasPrevPage = false;
  final int recordsPerPage = 20;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRegistros();
  }

  Future<void> fetchRegistros({int page = 1, String search = ''}) async {
    try {
      setState(() => isLoading = true);

      final result = await DatabaseHelper.obtenerIngresosSalidasPaginado(
        page: page,
        perPage: recordsPerPage,
        search: search,
      );

      if (mounted) {
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

        setState(() {
          registros = result['data'] as List<dynamic>? ?? [];
          currentPage = pagination['page'] ?? 1;
          totalPages = pagination['total_pages'] ?? 1;
          totalRecords = pagination['total'] ?? 0;
          hasNextPage = pagination['has_next'] ?? false;
          hasPrevPage = pagination['has_prev'] ?? false;
          searchQuery = search;
          ordenarRegistros();
          isLoading = false;
        });
      }
    } catch (e) {
      SafeLogger.error('Error al obtener ingresos/salidas', e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void ordenarRegistros() {
    setState(() {
      registros.sort((a, b) {
        switch (ordenActual) {
          case Orden.fechaDesc:
            final fechaA = a['fechahora'] ?? '';
            final fechaB = b['fechahora'] ?? '';
            return fechaB.compareTo(fechaA);
          case Orden.fechaAsc:
            final fechaA = a['fechahora'] ?? '';
            final fechaB = b['fechahora'] ?? '';
            return fechaA.compareTo(fechaB);
          case Orden.ingresoPrimero:
            final tipoA = (a['ingreso_salida'] ?? '').toString();
            final tipoB = (b['ingreso_salida'] ?? '').toString();
            if (tipoA == tipoB) {
              final fechaA = a['fechahora'] ?? '';
              final fechaB = b['fechahora'] ?? '';
              return fechaB.compareTo(fechaA);
            }
            return tipoA == 'Ingreso' ? -1 : 1;
          case Orden.salidaPrimero:
            final tipoA = (a['ingreso_salida'] ?? '').toString();
            final tipoB = (b['ingreso_salida'] ?? '').toString();
            if (tipoA == tipoB) {
              final fechaA = a['fechahora'] ?? '';
              final fechaB = b['fechahora'] ?? '';
              return fechaB.compareTo(fechaA);
            }
            return tipoA == 'Salida' ? -1 : 1;
        }
      });
    });
  }

  void showDetalleModal(Map<String, dynamic> registro) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${registro['maquina'] ?? 'Sin máquina'} (${registro['ingreso_salida']})',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código: ${registro['codigo'] ?? '-'}'),
              Text('Fecha y hora: ${registro['FECHAHORA']}'),
              if (registro['tiempo_formateado'] != null)
                Text('Tiempo transcurrido: ${registro['tiempo_formateado']}'),
              if (registro['fechahora_ultimo'] != null)
                Text(
                    'Fecha último movimiento: ${registro['fechahora_ultimo']}'),
              Text('Estado máquina: ${registro['ESTADO_MAQUINA'] ?? '-'}'),
              Text('Usuario: ${registro['usuario_nombre'] ?? 'Sin usuario'}'),
              if (registro['observaciones'] != null)
                Text('Observaciones: ${registro['observaciones']}'),
              if (registro['movimiento_anterior_texto'] != null)
                Text(
                    'Movimiento anterior: ${registro['movimiento_anterior_texto']}'),
              const SizedBox(height: 8),
              Text('ID: ${registro['id']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
    print('Registro en modal: $registro');
  }

  Color getTipoColor(String tipo) {
    final tipoNorm = tipo.toString().toUpperCase().trim();
    if (tipoNorm == 'INGRESO') return Colors.green.shade100;
    if (tipoNorm == 'SALIDA') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  void _navigateToRegistro() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistroScreen(usuarioId: widget.usuarioId),
        ),
      );
      if (result == true) {
        fetchRegistros();
      }
    } catch (e) {
      SafeLogger.error('Error al navegar a RegistroScreen', e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al abrir el registro: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos y Salidas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por máquina, usuario...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (value) {
                      fetchRegistros(page: 1, search: value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    fetchRegistros(page: 1, search: '');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<Orden>(
            icon: const Icon(Icons.sort),
            onSelected: (Orden result) {
              setState(() {
                ordenActual = result;
                ordenarRegistros();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Orden>>[
              const PopupMenuItem<Orden>(
                value: Orden.fechaDesc,
                child: Text('Fecha: más reciente primero'),
              ),
              const PopupMenuItem<Orden>(
                value: Orden.fechaAsc,
                child: Text('Fecha: más antigua primero'),
              ),
              const PopupMenuItem<Orden>(
                value: Orden.ingresoPrimero,
                child: Text('Ingresos primero'),
              ),
              const PopupMenuItem<Orden>(
                value: Orden.salidaPrimero,
                child: Text('Salidas primero'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de paginación
          if (!isLoading)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: $totalRecords registros',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Página $currentPage de $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Lista de registros
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : registros.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron registros',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final registro = registros[index];
                          print('Registro en lista: $registro');
                          final tipoNorm = (registro['ingreso_salida'] ?? '')
                              .toString()
                              .toUpperCase()
                              .trim();
                          final esIngreso = tipoNorm == 'INGRESO';
                          return Card(
                            color:
                                getTipoColor(registro['ingreso_salida'] ?? ''),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: Icon(
                                esIngreso
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: esIngreso ? Colors.green : Colors.red,
                                size: 32,
                              ),
                              title: Text(
                                registro['MAQUINA'] ?? 'Sin nombre',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fecha: ${registro['FECHAHORA']}'),
                                  if (registro['ESTADO_MAQUINA'] != null)
                                    Text(
                                        'Estado: ${registro['ESTADO_MAQUINA']}'),
                                  if (registro['tiempo_formateado'] != null)
                                    Text(
                                        'Tiempo: ${registro['tiempo_formateado']}',
                                        style: TextStyle(
                                            color: Colors.blue.shade600)),
                                  if (registro['usuario_nombre'] != null)
                                    Text(
                                        'Usuario: ${registro['usuario_nombre']}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                ],
                              ),
                              trailing: Text(
                                tipoNorm,
                                style: TextStyle(
                                  color: esIngreso ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => showDetalleModal(registro),
                            ),
                          );
                        },
                      ),
          ),

          // Controles de paginación
          if (!isLoading && totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: hasPrevPage
                        ? () => fetchRegistros(
                            page: currentPage - 1, search: searchQuery)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  TextButton(
                    onPressed: currentPage > 1
                        ? () => fetchRegistros(page: 1, search: searchQuery)
                        : null,
                    child: const Text('Primera'),
                  ),
                  const SizedBox(width: 16),
                  Text('$currentPage / $totalPages'),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: currentPage < totalPages
                        ? () => fetchRegistros(
                            page: totalPages, search: searchQuery)
                        : null,
                    child: const Text('Última'),
                  ),
                  IconButton(
                    onPressed: hasNextPage
                        ? () => fetchRegistros(
                            page: currentPage + 1, search: searchQuery)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRegistro,
        backgroundColor: Colors.blue,
        tooltip: 'Nuevo ingreso/salida',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
