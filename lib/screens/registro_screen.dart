import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';

class RegistroScreen extends StatefulWidget {
  final int usuarioId;
  const RegistroScreen({super.key, required this.usuarioId});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  int? _idMaquina;
  String _ingresoSalida = 'INGRESO';  // Backend espera "INGRESO" no "Ingreso"
  DateTime _fechaHora = DateTime.now();
  TimeOfDay _tiempo = TimeOfDay.now();
  String _editarFecha = 'No';
  String? _movimientoAnterior;
  DateTime? _fechaHoraUltimo;
  bool _isLoading = false;
  bool _loadingMaquinas = true;

  List<Map<String, dynamic>> _maquinas = [];

  @override
  void initState() {
    super.initState();
    _cargarMaquinas();
  }

  Future<void> _cargarMaquinas() async {
    try {
      final maquinas = await DatabaseHelper.obtenerMaquinas();
      setState(() {
        _maquinas = maquinas;
        _loadingMaquinas = false;
      });
    } catch (e) {
      SafeLogger.error('Error al cargar máquinas', e);
      setState(() {
        _loadingMaquinas = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar máquinas: $e')));
    }
  }

  Future<void> _guardar() async {
    if (_idMaquina == null) return;
    setState(() => _isLoading = true);
    try {
      final ok = await DatabaseHelper.registrarIngresoSalida(
        idMaquina: _idMaquina!,
        fechahora: _fechaHora.toIso8601String(),
        ingresoSalida: _ingresoSalida,
        estadoMaquina: 'OPERATIVA',  // Valor por defecto válido para el backend
        observaciones: null,
        usuarioId: widget.usuarioId,
      );
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro guardado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  Widget _buildFormField({
    required String label,
    bool required = false,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            required ? '$label *' : label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A6FAE),
        title: const Text('Ingreso/Salida de Máquina'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // 1. Máquina - Dropdown
            _buildFormField(
              label: 'Maquina',
              required: true,
              child: _loadingMaquinas
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _idMaquina,
                      items: _maquinas
                          .map<DropdownMenuItem<int>>(
                            (m) => DropdownMenuItem<int>(
                              value: m['pkMaquina'] as int,
                              child: Text(m['MAQUINA'] ?? 'Sin nombre'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _idMaquina = v),
                    ),
            ),
            const SizedBox(height: 20),

            // 2. INGRESO_SALIDA - Botones
            _buildFormField(
              label: 'INGRESO_SALIDA',
              required: true,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _ingresoSalida == 'INGRESO'  // Corregido
                            ? const Color(0xFF00B11F).withOpacity(0.1)
                            : Colors.white,
                        foregroundColor: _ingresoSalida == 'INGRESO'  // Corregido
                            ? const Color(0xFF00B11F)
                            : Colors.grey[600],
                        side: BorderSide(
                          color: _ingresoSalida == 'INGRESO'  // Corregido
                              ? const Color(0xFF00B11F)
                              : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          setState(() => _ingresoSalida = 'INGRESO'),  // Corregido
                      icon: Icon(
                        Icons.login,
                        color: _ingresoSalida == 'INGRESO'  // Corregido
                            ? const Color(0xFF00B11F)
                            : Colors.grey[600],
                      ),
                      label: const Text('Ingreso'),  // UI text stays friendly
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _ingresoSalida == 'SALIDA'  // Corregido
                            ? const Color(0xFFDA7A00).withOpacity(0.1)
                            : Colors.white,
                        foregroundColor: _ingresoSalida == 'SALIDA'  // Corregido
                            ? const Color(0xFFDA7A00)
                            : Colors.grey[600],
                        side: BorderSide(
                          color: _ingresoSalida == 'SALIDA'  // Corregido
                              ? const Color(0xFFDA7A00)
                              : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          setState(() => _ingresoSalida = 'SALIDA'),  // Corregido
                      icon: Icon(
                        Icons.logout,
                        color: _ingresoSalida == 'SALIDA'  // Corregido
                            ? const Color(0xFFDA7A00)
                            : Colors.grey[600],
                      ),
                      label: const Text('Salida'),  // UI text stays friendly
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. FECHAHORA - DateTime input
            _buildFormField(
              label: 'FECHAHORA',
              required: true,
              child: TextFormField(
                readOnly: _editarFecha == 'No',
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                  enabled: _editarFecha == 'Si',
                ),
                controller: TextEditingController(
                  text: _fechaHora.toIso8601String().substring(0, 16),
                ),
                onTap: _editarFecha == 'Si'
                    ? () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaHora,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_fechaHora),
                          );
                          if (hora != null) {
                            setState(() {
                              _fechaHora = DateTime(
                                fecha.year,
                                fecha.month,
                                fecha.day,
                                hora.hour,
                                hora.minute,
                              );
                            });
                          }
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // 4. Editar_Fecha - Botones Si/No
            _buildFormField(
              label: 'Modificar la fecha de entrada',
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _editarFecha == 'Si'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                        foregroundColor: _editarFecha == 'Si'
                            ? Colors.blue
                            : Colors.grey[600],
                        side: BorderSide(
                          color: _editarFecha == 'Si'
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => setState(() => _editarFecha = 'Si'),
                      child: const Text('Si'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _editarFecha == 'No'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                        foregroundColor: _editarFecha == 'No'
                            ? Colors.blue
                            : Colors.grey[600],
                        side: BorderSide(
                          color: _editarFecha == 'No'
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => setState(() => _editarFecha = 'No'),
                      child: const Text('No'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Movimiento anterior - Solo lectura
            _buildFormField(
              label: 'Movimiento anterior',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: Text(
                  _movimientoAnterior ?? 'No hay movimientos anteriores',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. FECHAHORA_ULTIMO - Solo lectura
            _buildFormField(
              label: 'FECHAHORA_ULTIMO',
              child: TextFormField(
                enabled: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text:
                      _fechaHoraUltimo?.toIso8601String().substring(0, 16) ??
                      '',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 7. TIEMPO - Input de tiempo
            _buildFormField(
              label: 'TIEMPO',
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: Icon(Icons.access_time),
                ),
                controller: TextEditingController(
                  text:
                      '${_tiempo.hour.toString().padLeft(2, '0')}:${_tiempo.minute.toString().padLeft(2, '0')}:00',
                ),
                onTap: () async {
                  final tiempo = await showTimePicker(
                    context: context,
                    initialTime: _tiempo,
                  );
                  if (tiempo != null) {
                    setState(() {
                      _tiempo = tiempo;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A6FAE),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _guardar,
                    child: const Text(
                      'Guardar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
