import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:harcha_maquinaria/services/database_helper.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

class RecargaCombustibleScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;

  const RecargaCombustibleScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  @override
  State<RecargaCombustibleScreen> createState() =>
      _RecargaCombustibleScreenState();
}

class _RecargaCombustibleScreenState extends State<RecargaCombustibleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litrosController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _horometroController = TextEditingController();
  final _kilometrosController = TextEditingController();
  final _patenteController = TextEditingController();

  int? _idMaquina;
  int? _obraId;
  int? _clienteId;
  int? _operadorId;
  String? _rutOperador;
  String? _nombreOperador;
  String _patente = '';
  DateTime _fechaHora = DateTime.now();

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _loadingOperadores = false;

  List<Map<String, dynamic>> _maquinas = [];
  List<Map<String, dynamic>> _obras = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _operadores = []; // ✅ OPERADORES DINÁMICOS

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ✅ CARGAR DATOS USANDO DATABASEHELPER
  Future<void> _cargarDatos() async {
    setState(() => _isLoadingData = true);

    try {
      // ✅ USAR MÉTODOS DEL DATABASE HELPER
      final futures = await Future.wait([
        DatabaseHelper.obtenerMaquinas(),
        DatabaseHelper.obtenerObras(),
        DatabaseHelper.obtenerClientes(),
      ]);

      setState(() {
        _maquinas = _filtrarMaquinasValidas(futures[0]);
        _obras = futures[1];
        _clientes = futures[2];
        _isLoadingData = false;
      });

      SafeLogger.debug(
        'Datos cargados: ${_maquinas.length} máquinas, ${_obras.length} obras, ${_clientes.length} clientes',
      );
    } catch (e) {
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filtrarMaquinasValidas(
    List<Map<String, dynamic>> maquinas,
  ) {
    return maquinas.where((maquina) {
      final nombre = maquina['MAQUINA']?.toString();
      final codigo = maquina['CODIGO_MAQUINA']?.toString();
      return (nombre != null && nombre.trim().isNotEmpty) ||
          (codigo != null && codigo.trim().isNotEmpty);
    }).toList();
  }

  int? _extraerId(Map<String, dynamic> item) {
    final campos = [
      'id',
      'pkUsuario',
      'usuario_id',
      'operador_id',
      'pk_operador',
    ];

    for (var campo in campos) {
      final valor = item[campo];
      if (valor != null) {
        if (valor is int && valor > 0) return valor;
        if (valor is String) {
          final parsed = int.tryParse(valor);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }
    return null;
  }

  String _extraerNombre(Map<String, dynamic> item) {
    final campos = [
      'nombre_completo',
      'nombre',
      'usuario',
      'NOMBREUSUARIO',
      'display_name',
    ];

    for (var campo in campos) {
      final valor = item[campo];
      if (valor != null) {
        final nombre = valor.toString().trim();
        if (nombre.isNotEmpty && nombre != 'null') {
          return nombre;
        }
      }
    }
    return '';
  }

  Future<void> _cargarOperadoresMaquina(int maquinaId) async {
    setState(() {
      _loadingOperadores = true;
      _operadorId = null;
      _operadores.clear();
    });

    try {
      SafeLogger.debug('Cargando operadores para máquina ID: $maquinaId');

      final operadoresData = await DatabaseHelper.obtenerOperadoresMaquina(
        maquinaId,
      );
      SafeLogger.debug('Response completa', operadoresData);

      final operadoresValidos = <Map<String, dynamic>>[];

      if (operadoresData.isNotEmpty) {
        for (int i = 0; i < operadoresData.length; i++) {
          final item = operadoresData[i];
          SafeLogger.debug('Procesando operador', item);

          final id = _extraerId(item);
          final nombre = _extraerNombre(item);

          SafeLogger.debug('Extraído ID: $id, Nombre: $nombre');

          if (nombre.isNotEmpty && nombre != 'null') {
            operadoresValidos.add({
              'id': id,
              'nombre': nombre,
              'original': item,
            });
            SafeLogger.debug('Operador Válido agregado');
          } else {
            SafeLogger.debug(
                'Operador inválido (nombre vacío o nulo), se omite');
          }
        }
      }

      SafeLogger.debug(
        'Operadores cargados para máquina $maquinaId: ${operadoresValidos.length}',
      );
      for (var op in operadoresValidos) {
        SafeLogger.debug('Operador: ID=${op['id']}, Nombre=${op['nombre']}');
      }

      if (mounted) {
        setState(() {
          _operadores = operadoresValidos;
          _loadingOperadores = false;
        });
      }
    } catch (e) {
      SafeLogger.error('Error al cargar operadores', e);
      if (mounted) {
        setState(() {
          _operadores = [];
          _loadingOperadores = false;
        });
      }
    }
  }

  String _obtenerNombreOperadorSeleccionado() {
    if (_operadorId == null) return '';

    try {
      final operador = _operadores.firstWhere(
        (op) => op['id'] == _operadorId,
        orElse: () => {'nombre': 'Operador desconocido'},
      );
      return operador['nombre'] as String;
    } catch (e) {
      return 'Operador desconocido';
    }
  }

  Future<void> _cargarDatosOperador(int operadorId) async {
    try {
      SafeLogger.debug('Cargando datos del operador ID: $operadorId');
      final operadorData =
          await DatabaseHelper.obtenerOperadorPorId(operadorId);

      setState(() {
        _rutOperador = operadorData['RUT'];
        _nombreOperador =
            operadorData['usuario'] ?? operadorData['NOMBREUSUARIO'];
      });

      SafeLogger.debug(
          'Datos del operador cargados - RUT: $_rutOperador, Nombre: $_nombreOperador');
    } catch (e) {
      SafeLogger.error('Error al cargar datos del operador', e);
      setState(() {
        _rutOperador = null;
        _nombreOperador = null;
      });
    }
  }

  void _onMaquinaChanged(int? maquinaId) {
    setState(() {
      _idMaquina = maquinaId;
      _operadorId = null; // ✅ RESETEAR OPERADOR
      _operadores.clear(); // ✅ LIMPIAR LISTA

      if (maquinaId != null) {
        // Encontrar máquina seleccionada
        final maquinaSeleccionada = _maquinas.firstWhere(
          (m) => m['pkMaquina'] == maquinaId,
          orElse: () => <String, dynamic>{},
        );

        _patente = maquinaSeleccionada['PATENTE']?.toString() ?? '';
        _patenteController.text = _patente; // ✅ ACTUALIZAR EL CONTROLADOR

        // Cargar operadores
        _cargarOperadoresMaquina(maquinaId);
      } else {
        _patente = '';
        _patenteController.text = ''; // ✅ LIMPIAR EL CONTROLADOR
      }
    });
  }

  String _getNombreMaquina(Map<String, dynamic> maquina) {
    final nombre = maquina['MAQUINA']?.toString();
    final patente = maquina['PATENTE']?.toString();

    String resultado = '';

    if (nombre != null && nombre.trim().isNotEmpty) {
      resultado += nombre;
    } else {
      resultado += 'Sin nombre';
    }

    if (patente != null && patente.trim().isNotEmpty) {
      resultado += ' - $patente';
    }

    return resultado.trim();
  }

  String _getNombreObra(Map<String, dynamic> obra) {
    final codigo = obra['ID_OBRA']?.toString();
    final nombre = obra['OBRA']?.toString() ?? 'Sin nombre';

    if (codigo != null && codigo.trim().isNotEmpty) {
      return '[$codigo] $nombre';
    }
    return nombre;
  }

  String _getNombreCliente(Map<String, dynamic> cliente) {
    return cliente['CLIENTE']?.toString() ?? 'Sin nombre';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idMaquina == null || _obraId == null || _clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final litros = double.tryParse(_litrosController.text) ?? 0.0;
      final odometro = _horometroController.text.isNotEmpty
          ? double.tryParse(_horometroController.text)
          : null;
      final kilometros = _kilometrosController.text.isNotEmpty
          ? double.tryParse(_kilometrosController.text)
          : null;

      final result = await DatabaseHelper.registrarRecargaCombustible(
        idMaquina: _idMaquina!,
        usuarioId: widget.usuarioId,
        operadorId: _operadorId,
        rutOperador: _rutOperador,
        nombreOperador: _nombreOperador,
        fechahora: _fechaHora.toIso8601String(),
        litros: litros,
        obraId: _obraId!,
        clienteId: _clienteId!,
        foto: null,
        observaciones: _observacionesController.text.isEmpty
            ? null
            : _observacionesController.text,
        odometro: odometro,
        kilometros: kilometros,
        patente: _patente.isEmpty ? null : _patente,
      );

      if (result['success'] == true) {
        final isOffline = result['offline'] == true;
        final message = isOffline
            ? 'Recarga guardada offline${result['codigo_recarga'] != null ? ': ${result['codigo_recarga']}' : ''}\n(Se sincronizará automáticamente cuando haya conexión)'
            : 'Recarga registrada correctamente${result['codigo_recarga'] != null ? ': ${result['codigo_recarga']}' : ''}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
            duration: Duration(seconds: isOffline ? 5 : 3),
          ),
        );

        // Limpiar formulario
        _limpiarFormulario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message'] ?? 'Error desconocido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  void _limpiarFormulario() {
    setState(() {
      _idMaquina = null;
      _obraId = null;
      _clienteId = null;
      _operadorId = null;
      _rutOperador = null;
      _nombreOperador = null;
      _patente = '';
      _fechaHora = DateTime.now();
      _operadores.clear();
    });

    _litrosController.clear();
    _observacionesController.clear();
    _horometroController.clear();
    _kilometrosController.clear();
    _patenteController.clear(); // ✅ LIMPIAR CONTROLADOR DE PATENTE
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Expanded(
                  child: Text('Nueva Recarga de Combustible'),
                ),
                // Indicador de conectividad
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: authProvider.isOnline ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        authProvider.isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        authProvider.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarDatos,
                tooltip: 'Actualizar datos',
              ),
            ],
          ),
          body: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ✅ FECHA Y HORA
                        InkWell(
                          onTap: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaHora,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 1)),
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
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha y Hora *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              '${_fechaHora.day.toString().padLeft(2, '0')}/${_fechaHora.month.toString().padLeft(2, '0')}/${_fechaHora.year} '
                              '${_fechaHora.hour.toString().padLeft(2, '0')}:'
                              '${_fechaHora.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ MÁQUINA
                        DropdownButtonFormField<int>(
                          value: _idMaquina,
                          decoration: const InputDecoration(
                            labelText: 'Máquina *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.build),
                          ),
                          items:
                              _maquinas.map<DropdownMenuItem<int>>((maquina) {
                            final nombre = _getNombreMaquina(maquina);

                            return DropdownMenuItem<int>(
                              value: maquina['pkMaquina'],
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ), // ✅ LIMITAR ANCHO
                                child: Text(
                                  nombre,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onMaquinaChanged,
                          validator: (value) {
                            if (value == null) return 'Seleccione una máquina';
                            return null;
                          },
                          // ✅ CONFIGURACIONES ADICIONALES PARA EVITAR OVERFLOW
                          isExpanded: true,
                          menuMaxHeight: 300,
                        ),

                        const SizedBox(height: 16),

                        // ✅ PETROLERO (USUARIO LOGUEADO - READONLY)
                        TextFormField(
                          initialValue: widget.usuarioNombre,
                          decoration: const InputDecoration(
                            labelText: 'Petrolero *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            helperText: 'Usuario logueado (automático)',
                          ),
                          readOnly: true,
                          style: TextStyle(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 16),

                        // ✅ OPERADOR
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_idMaquina == null)
                              // Cuando no hay máquina seleccionada
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.engineering, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Seleccione una máquina para ver operadores',
                                        style: TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_loadingOperadores)
                              // Cuando está cargando
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.blue.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Cargando operadores...'),
                                  ],
                                ),
                              )
                            else if (_operadores.isEmpty)
                              // Cuando no hay operadores
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.orange.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.orange),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Esta máquina no tiene operadores asignados',
                                        style: TextStyle(color: Colors.orange),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              // Dropdown normal cuando hay operadores
                              DropdownButtonFormField<int>(
                                value: _operadorId,
                                decoration: const InputDecoration(
                                  labelText: 'Operador (Opcional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.engineering),
                                ),
                                hint: const Text('Seleccionar operador'),
                                onChanged: (int? value) {
                                  setState(() {
                                    _operadorId = value;
                                    _rutOperador = null;
                                    _nombreOperador = null;
                                  });

                                  // Cargar datos del operador si se seleccionó uno
                                  if (value != null) {
                                    _cargarDatosOperador(value);
                                  }
                                },
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text(
                                      'Sin operador asignado',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ..._operadores.map<DropdownMenuItem<int>>((
                                    operador,
                                  ) {
                                    final id = operador['id'] as int;
                                    final nombre = operador['nombre'] as String;

                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        nombre,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            if (_operadorId != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Operador: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _obtenerNombreOperadorSeleccionado(),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _operadorId = null;
                                        });
                                      },
                                      tooltip: 'Quitar operador',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ✅ PATENTE (AUTOMÁTICO)
                        TextFormField(
                          controller: _patenteController,
                          decoration: const InputDecoration(
                            labelText: 'Patente',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                            helperText: 'Se completa automáticamente',
                          ),
                          readOnly: true,
                          style: TextStyle(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 16),

                        // ✅ HORÓMETRO
                        TextFormField(
                          controller: _horometroController,
                          decoration: const InputDecoration(
                            labelText: 'Horómetro',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                            suffixText: 'Hr',
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // ✅ KILÓMETROS
                        TextFormField(
                          controller: _kilometrosController,
                          decoration: const InputDecoration(
                            labelText: 'Kilómetros *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.route),
                            suffixText: 'km',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese los kilómetros';
                            }
                            final km = double.tryParse(value);
                            if (km == null || km < 0) {
                              return 'Ingrese un valor válido mayor o igual a 0';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ✅ LITROS
                        TextFormField(
                          controller: _litrosController,
                          decoration: const InputDecoration(
                            labelText: 'Litros *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_gas_station),
                            suffixText: 'L',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese los litros';
                            }
                            final litros = double.tryParse(value);
                            if (litros == null || litros <= 0) {
                              return 'Ingrese un valor válido mayor a 0';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ✅ OBRA
                        DropdownButtonFormField<int>(
                          value: _obraId,
                          decoration: const InputDecoration(
                            labelText: 'Obra *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          items: _obras.map((obra) {
                            return DropdownMenuItem<int>(
                              value: obra['pkObra'],
                              child: Text(
                                _getNombreObra(obra),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _obraId = value),
                          validator: (value) {
                            if (value == null) return 'Seleccione una obra';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ✅ CLIENTE
                        DropdownButtonFormField<int>(
                          value: _clienteId,
                          decoration: const InputDecoration(
                            labelText: 'Cliente *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: _clientes.map((cliente) {
                            return DropdownMenuItem<int>(
                              value: cliente['pkCliente'],
                              child: Text(
                                _getNombreCliente(cliente),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _clienteId = value),
                          validator: (value) {
                            if (value == null) return 'Seleccione un cliente';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ✅ OBSERVACIONES
                        TextFormField(
                          controller: _observacionesController,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),

                        // ✅ BOTÓN GUARDAR
                        ElevatedButton(
                          onPressed: _isLoading ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Guardar Recarga',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _litrosController.dispose();
    _observacionesController.dispose();
    _horometroController.dispose();
    _kilometrosController.dispose();
    _patenteController.dispose();
    super.dispose();
  }
}
