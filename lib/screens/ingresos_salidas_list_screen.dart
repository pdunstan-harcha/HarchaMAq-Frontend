import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';
import 'registro_screen.dart';

enum Orden { fechaDesc, fechaAsc, ingresoPrimero, salidaPrimero }

class IngresosSalidasListScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;
  const IngresosSalidasListScreen({super.key, required this.usuarioId, this.usuarioNombre = ''});

  @override
  _IngresosSalidasListScreenState createState() =>
      _IngresosSalidasListScreenState();
}

class _IngresosSalidasListScreenState extends State<IngresosSalidasListScreen> {
  List<dynamic> registros = [];
  bool isLoading = true;
  Orden ordenActual = Orden.fechaDesc;


  @override
  void initState() {
    super.initState();
    fetchRegistros();
  }

  Future<void> fetchRegistros() async {
    try {
      final data = await DatabaseHelper.obtenerIngresosSalidas();
      if (mounted) {
        setState(() {
          registros = data;
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
            '${registro['maquina_nombre'] ?? 'Sin máquina'} (${registro['ingreso_salida']})',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código: ${registro['codigo'] ?? '-'}'),
              Text('Fecha y hora: ${registro['fechahora']}'),
              Text('Estado: ${registro['estado_maquina']}'),
              Text('Operador: ${registro['usuario_nombre'] ?? 'Sin operador'}'),
              Text('Observaciones: ${registro['observaciones'] ?? "-"}'),
              Text('ID: ${registro['id']}'),
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
  }

  Color getTipoColor(String tipo) {
    final tipoNorm = tipo.toString().toUpperCase().trim();
    if (tipoNorm == 'INGRESO') return Colors.green.shade100;
    if (tipoNorm == 'SALIDA') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  void _navigateToRegistro() async{
    try {
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegistroScreen(usuarioId: widget.usuarioId
        ),
        ),
        );
        if(result == true){
          fetchRegistros();
        }
    }catch(e){
      SafeLogger.error('Error al navegar a RegistroScreen', e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir el registro: ${e.toString()}'),
      backgroundColor: Colors.red,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos y Salidas'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final registro = registros[index];
                final tipoNorm = (registro['ingreso_salida'] ?? '')
                    .toString()
                    .toUpperCase()
                    .trim();
                final esIngreso = tipoNorm == 'INGRESO';
                return Card(
                  color: getTipoColor(registro['ingreso_salida'] ?? ''),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: Icon(
                      esIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                      color: esIngreso ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      registro['maquina_nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Fecha: ${registro['fechahora']}\nEstado: ${registro['estado_maquina']}',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRegistro,
        backgroundColor: Colors.blue,
        tooltip: 'Nuevo ingreso/salida',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
