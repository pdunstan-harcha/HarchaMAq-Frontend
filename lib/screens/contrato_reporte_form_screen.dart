import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/database_helper.dart';
import '../config.dart';

class ContratoReporteFormScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;
  final String? token;

  const ContratoReporteFormScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioNombre,
    this.token,
  });

  @override
  State<ContratoReporteFormScreen> createState() =>
      _ContratoReporteFormScreenState();
}

class _ContratoReporteFormScreenState extends State<ContratoReporteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos de texto
  final _descripcionController = TextEditingController(); // Trabajo realizado
  final _observacionesController = TextEditingController();
  final _incidenteController =
      TextEditingController(); // Reportar suceso incidente
  final _horasTrabajadasController = TextEditingController();
  final _horasMinimasController = TextEditingController();
  final _odometroInicialController = TextEditingController();
  final _odometroFinalController = TextEditingController();
  final _kmInicialController = TextEditingController();
  final _kmFinalController = TextEditingController();
  final _kmTotalController = TextEditingController(); // Kilómetros calculados

  // Variables para fechas, selecciones y archivos
  DateTime _fechaReporte = DateTime.now();
  int? _maquinaId;
  int? _contratoId;
  String? _estadoReporte = 'Correcto'; // Por defecto Correcto
  String? _trabajoRealizado;
  File? _foto1;
  File? _foto2;

  // Listas para dropdowns
  List<Map<String, dynamic>> _maquinas = [];
  List<Map<String, dynamic>> _contratos = [];
  List<Map<String, dynamic>> _contratosFiltrados = [];

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _loadingContratos = false;

  // Opciones para trabajo realizado según el HTML
  final List<String> _opcionesTrabajoRealizado = [
    'Transporte',
    'Excavación',
    'Compactación',
    'Nivelación',
    'Carga',
    'Descarga',
    'Mantenimiento',
    'Limpieza',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();

    // Escuchar cambios en los campos de KM para calcular automáticamente la diferencia
    _kmInicialController.addListener(_calcularKilometros);
    _kmFinalController.addListener(_calcularKilometros);
  }

  @override
  void dispose() {
    _kmInicialController.removeListener(_calcularKilometros);
    _kmFinalController.removeListener(_calcularKilometros);

    _descripcionController.dispose();
    _observacionesController.dispose();
    _incidenteController.dispose();
    _horasTrabajadasController.dispose();
    _horasMinimasController.dispose();
    _odometroInicialController.dispose();
    _odometroFinalController.dispose();
    _kmInicialController.dispose();
    _kmFinalController.dispose();
    _kmTotalController.dispose();

    super.dispose();
  }

  void _calcularKilometros() {
    // Calcula la diferencia entre KM final e inicial
    final kmInicial = double.tryParse(_kmInicialController.text) ?? 0;
    final kmFinal = double.tryParse(_kmFinalController.text) ?? 0;
    final diferencia = kmFinal - kmInicial;

    // Actualiza el campo de kilómetros calculados
    setState(() {
      _kmTotalController.text = diferencia.toString();
    });
  }

  void _calcularHorasTrabajadas() {
    // Calcula la diferencia entre horómetro final e inicial
    final odometroInicial =
        double.tryParse(_odometroInicialController.text) ?? 0;
    final odometroFinal = double.tryParse(_odometroFinalController.text) ?? 0;
    final diferencia = odometroFinal - odometroInicial;

    // Actualiza el campo de horas trabajadas
    setState(() {
      _horasTrabajadasController.text = diferencia.toString();
    });
  }

  Future<void> _cargarContratosPorMaquina(int? maquinaId) async {
    if (maquinaId == null) {
      setState(() {
        _contratosFiltrados = [];
        _loadingContratos = false;
      });
      return;
    }

    setState(() {
      _loadingContratos = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.getApiUrl()}/contratos?maquina_id=$maquinaId'),
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _contratosFiltrados = List<Map<String, dynamic>>.from(data);
          _loadingContratos = false;
        });
      } else {
        throw Exception('Error al cargar contratos');
      }
    } catch (e) {
      setState(() {
        _loadingContratos = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar contratos: $e')),
        );
      }
    }
  }

  Future<void> _cargarDatos() async {
    try {
      final futures = await Future.wait([
        DatabaseHelper.obtenerMaquinas(),
        DatabaseHelper.obtenerContratos(),
      ]);

      setState(() {
        _maquinas = futures[0];
        _contratos = futures[1];
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaReporte,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      setState(() => _fechaReporte = fecha);
    }
  }

  Future<void> _tomarFoto(int numeroFoto) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Mostrar opciones: cámara o galería
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? imagen = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (imagen != null) {
        setState(() {
          if (numeroFoto == 1) {
            _foto1 = File(imagen.path);
          } else {
            _foto2 = File(imagen.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _guardarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verificaciones adicionales
    if (_maquinaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una máquina')),
      );
      return;
    }

    if (_contratoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un contrato/obra')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertir imágenes a base64 si las hay
      String? foto1Base64;
      String? foto2Base64;

      if (_foto1 != null) {
        final bytes1 = await _foto1!.readAsBytes();
        foto1Base64 = base64Encode(bytes1);
      }

      if (_foto2 != null) {
        final bytes2 = await _foto2!.readAsBytes();
        foto2Base64 = base64Encode(bytes2);
      }

      // Obtener datos de la máquina y contrato seleccionados
      final maquina = _maquinas.firstWhere(
        (m) => m['pkMaquina'] == _maquinaId,
        orElse: () => {'MAQUINA': 'No encontrada', 'MARCA': '', 'MODELO': ''},
      );

      final contrato = _contratos.firstWhere(
        (c) => c['pkContrato'] == _contratoId,
        orElse: () => {'NOMBRE_CONTRATO': 'No encontrado'},
      );

      // Calcular kilómetros recorridos
      final kmInicial = double.tryParse(_kmInicialController.text) ?? 0;
      final kmFinal = double.tryParse(_kmFinalController.text) ?? 0;
      final kilometros = kmFinal - kmInicial;

      // Datos para enviar al servidor
      final resultado = await DatabaseHelper.registrarContratoReporte(
        fechaReporte: _fechaReporte.toIso8601String(),
        pkMaquina: _maquinaId!,
        maquinaTxt: maquina['MAQUINA'] ?? '',
        pkContrato: _contratoId!,
        contratoTxt: contrato['NOMBRE_CONTRATO'] ?? '',
        odometroInicial: double.tryParse(_odometroInicialController.text) ?? 0,
        odometroFinal: double.tryParse(_odometroFinalController.text) ?? 0,
        horasTrabajadas: double.tryParse(_horasTrabajadasController.text) ?? 0,
        horasMinimas: double.tryParse(_horasMinimasController.text) ?? 0,
        kmInicial: kmInicial,
        kmFinal: kmFinal,
        kilometros: kilometros,
        trabajoRealizado: _descripcionController.text,
        estadoReporte: _estadoReporte ?? 'Correcto',
        observaciones: _observacionesController.text,
        incidente: _incidenteController.text,
        foto1: foto1Base64,
        foto2: foto2Base64,
        usuarioId: widget.usuarioId,
        usuarioNombre: widget.usuarioNombre,
      );

      setState(() => _isLoading = false);

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte registrado correctamente')),
        );
        Navigator.of(context).pop(true); // Regresa con resultado de éxito
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${resultado['message']}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar reporte: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Diario'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _guardarReporte,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fecha Reporte
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha reporte',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd-MM-yyyy').format(_fechaReporte),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Máquina
                    DropdownButtonFormField<int>(
                      value: _maquinaId,
                      decoration: const InputDecoration(
                        labelText: 'Máquina *',
                        border: OutlineInputBorder(),
                      ),
                      items: _maquinas
                          .where(
                            (m) =>
                                m['MAQUINA'] != null &&
                                m['MAQUINA'].toString().isNotEmpty,
                          )
                          .map((maquina) {
                            return DropdownMenuItem<int>(
                              value: maquina['pkMaquina'],
                              child: Text(maquina['MAQUINA'].toString()),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _maquinaId = value;
                          _contratoId =
                              null; // Reset contrato when machine changes
                        });
                        _cargarContratosPorMaquina(value);
                      },
                      validator: (value) {
                        if (value == null) return 'Seleccione una máquina';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contrato/Obra
                    DropdownButtonFormField<int>(
                      value: _contratoId,
                      decoration: InputDecoration(
                        labelText: 'Contrato/Obra *',
                        border: const OutlineInputBorder(),
                        helperText: _maquinaId == null
                            ? 'Seleccione primero una máquina'
                            : _loadingContratos
                            ? 'Cargando contratos...'
                            : null,
                      ),
                      items:
                          (_maquinaId != null
                                  ? _contratosFiltrados
                                  : _contratos)
                              .map((contrato) {
                                return DropdownMenuItem<int>(
                                  value: contrato['pkContrato'],
                                  child: Text(
                                    contrato['NOMBRE_CONTRATO'] ?? '',
                                  ),
                                );
                              })
                              .toList(),
                      onChanged: _maquinaId == null || _loadingContratos
                          ? null
                          : (value) {
                              setState(() => _contratoId = value);
                            },
                      validator: (value) {
                        if (value == null) return 'Seleccione un contrato/obra';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hodómetro Inicial
                    TextFormField(
                      controller: _odometroInicialController,
                      decoration: InputDecoration(
                        labelText: 'Hodómetro inicial',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _odometroInicialController.text,
                                    ) ??
                                    0;
                                _odometroInicialController.text = (valor - 1)
                                    .toString();
                                _calcularHorasTrabajadas();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _odometroInicialController.text,
                                    ) ??
                                    0;
                                _odometroInicialController.text = (valor + 1)
                                    .toString();
                                _calcularHorasTrabajadas();
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calcularHorasTrabajadas(),
                    ),
                    const SizedBox(height: 16),

                    // Hodómetro Final
                    TextFormField(
                      controller: _odometroFinalController,
                      decoration: InputDecoration(
                        labelText: 'Hodómetro final',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _odometroFinalController.text,
                                    ) ??
                                    0;
                                _odometroFinalController.text = (valor - 1)
                                    .toString();
                                _calcularHorasTrabajadas();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _odometroFinalController.text,
                                    ) ??
                                    0;
                                _odometroFinalController.text = (valor + 1)
                                    .toString();
                                _calcularHorasTrabajadas();
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calcularHorasTrabajadas(),
                    ),
                    const SizedBox(height: 16),

                    // Horas Trabajadas (calculado automáticamente)
                    TextFormField(
                      controller: _horasTrabajadasController,
                      decoration: InputDecoration(
                        labelText: 'Horas Trabajadas *',
                        border: const OutlineInputBorder(),
                        errorText: _validarHorasTrabajadas(),
                        helperText:
                            'Calculado automáticamente (Horómetro final - inicial)',
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Las horas trabajadas se calculan automáticamente';
                        }
                        final horas = double.tryParse(value);
                        if (horas == null) {
                          return 'Valor calculado inválido';
                        }
                        if (horas < 0) {
                          return 'El número de horas trabajadas debe ser mayor que 0';
                        }
                        return null;
                      },
                    ),
                    if (_validarHorasTrabajadas() != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'El número de horas trabajadas debe ser mayor que 0',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Horas Mínimas
                    TextFormField(
                      controller: _horasMinimasController,
                      decoration: InputDecoration(
                        labelText: 'Horas mínimas',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _horasMinimasController.text,
                                    ) ??
                                    0;
                                _horasMinimasController.text = (valor - 1)
                                    .toString();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _horasMinimasController.text,
                                    ) ??
                                    0;
                                _horasMinimasController.text = (valor + 1)
                                    .toString();
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // KM Inicial
                    TextFormField(
                      controller: _kmInicialController,
                      decoration: InputDecoration(
                        labelText: 'KM inicial',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _kmInicialController.text,
                                    ) ??
                                    0;
                                _kmInicialController.text = (valor - 1)
                                    .toString();
                                _calcularKilometros();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final valor =
                                    double.tryParse(
                                      _kmInicialController.text,
                                    ) ??
                                    0;
                                _kmInicialController.text = (valor + 1)
                                    .toString();
                                _calcularKilometros();
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // KM Final
                    TextFormField(
                      controller: _kmFinalController,
                      decoration: InputDecoration(
                        labelText: 'KM final *',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final valor =
                                    double.tryParse(_kmFinalController.text) ??
                                    0;
                                _kmFinalController.text = (valor - 1)
                                    .toString();
                                _calcularKilometros();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final valor =
                                    double.tryParse(_kmFinalController.text) ??
                                    0;
                                _kmFinalController.text = (valor + 1)
                                    .toString();
                                _calcularKilometros();
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Kilómetros (editable)
                    TextFormField(
                      controller: _kmTotalController,
                      decoration: InputDecoration(
                        labelText: 'Kilómetros',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final valor =
                                    double.tryParse(_kmTotalController.text) ??
                                    0;
                                _kmTotalController.text = (valor - 1)
                                    .toString();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final valor =
                                    double.tryParse(_kmTotalController.text) ??
                                    0;
                                _kmTotalController.text = (valor + 1)
                                    .toString();
                              },
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    if (double.tryParse(_kmTotalController.text) != null &&
                        double.parse(_kmTotalController.text) < 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'KM no puede tener un valor negativo',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Trabajo Realizado
                    DropdownButtonFormField<String>(
                      value: _trabajoRealizado,
                      decoration: const InputDecoration(
                        labelText: 'Trabajo realizado',
                        border: OutlineInputBorder(),
                      ),
                      items: _opcionesTrabajoRealizado.map((trabajo) {
                        return DropdownMenuItem<String>(
                          value: trabajo,
                          child: Text(trabajo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _trabajoRealizado = value;
                          _descripcionController.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleccione el tipo de trabajo realizado';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Estado del Reporte
                    Row(
                      children: [
                        const Expanded(child: Text('Estado_Reporte')),
                        Radio(
                          value: 'Correcto',
                          groupValue: _estadoReporte,
                          onChanged: (String? value) {
                            setState(() {
                              _estadoReporte = value;
                            });
                          },
                        ),
                        const Text('Correcto'),
                        Radio(
                          value: 'No válido',
                          groupValue: _estadoReporte,
                          onChanged: (String? value) {
                            setState(() {
                              _estadoReporte = value;
                            });
                          },
                        ),
                        const Text('No válido'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Observaciones
                    const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Observaciones sobre el trabajo realizado',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Reporte pane
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Reporte pane',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _incidenteController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Fotografías
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Fotografías',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // FOTO1
                    InkWell(
                      onTap: () => _tomarFoto(1),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _foto1 != null
                            ? Image.file(_foto1!, fit: BoxFit.cover)
                            : const Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FOTO2
                    InkWell(
                      onTap: () => _tomarFoto(2),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _foto2 != null
                            ? Image.file(_foto2!, fit: BoxFit.cover)
                            : const Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Usuario (no editable)
                    DropdownButtonFormField<String>(
                      value: widget.usuarioNombre,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: widget.usuarioNombre,
                          child: Text(widget.usuarioNombre),
                        ),
                      ],
                      onChanged: null, // No es editable
                    ),
                    const SizedBox(height: 32),

                    // Botón de guardar (alternativo para pantalla grande)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarReporte,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('GUARDAR REPORTE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Método para validar horas trabajadas
  String? _validarHorasTrabajadas() {
    final texto = _horasTrabajadasController.text;
    if (texto.isEmpty) return null;

    final horas = double.tryParse(texto);
    if (horas == null) return 'Ingrese un número válido';
    if (horas < 0) return 'El número de horas trabajadas debe ser mayor que 0';

    return null;
  }
}
