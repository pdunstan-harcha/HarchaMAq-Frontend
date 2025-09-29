import 'package:flutter/material.dart';
import 'registro_screen.dart';
import 'recargas_list_screen.dart';
import 'recarga_combustible_screen.dart';
import 'contratos_reportes_list_screen.dart';
import 'contrato_reporte_form_screen.dart';
import 'ingresos_salidas_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const DashboardScreen({super.key, required this.usuario});

  String get _usuarioNombre {
    try {
      final nombre = usuario['NOMBRE'];
      final apellidos = usuario['APELLIDOS'];

      String nombreCompleto = '';

      if (nombre != null && nombre.toString().trim().isNotEmpty) {
        nombreCompleto += nombre.toString().trim();
      }

      if (apellidos != null && apellidos.toString().trim().isNotEmpty) {
        if (nombreCompleto.isNotEmpty) nombreCompleto += ' ';
        nombreCompleto += apellidos.toString().trim();
      }

      if (nombreCompleto.isNotEmpty) return nombreCompleto;

      final nombreUsuario = usuario['NOMBREUSUARIO'];
      if (nombreUsuario != null && nombreUsuario.toString().trim().isNotEmpty) {
        return nombreUsuario.toString().trim();
      }

      return 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  int get _usuarioId {
    try {
      final pkUsuario = usuario['pkUsuario'];
      if (pkUsuario is int) return pkUsuario;
      if (pkUsuario != null) {
        final parsed = int.tryParse(pkUsuario.toString());
        if (parsed != null) return parsed;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }

  String get _usuarioRol {
    try {
      final rol = usuario['ROL'];
      if (rol != null && rol.toString().trim().isNotEmpty) {
        return rol.toString().trim();
      }
      return 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Entrando a DashboardScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Harcha'),
        backgroundColor: const Color(0xFF6A6FAE),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Hola, $_usuarioNombre',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ TARJETA DE BIENVENIDA COMPACTA
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6A6FAE),
                      radius: 20,
                      child: Text(
                        _usuarioNombre.isNotEmpty
                            ? _usuarioNombre[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, $_usuarioNombre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _usuarioRol,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ TÍTULO
            const Text(
              'Módulos del Sistema',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // ✅ MÓDULOS AGRUPADOS (3 TARJETAS VERTICALES)
            Expanded(
              child: ListView(
                children: [
                  // 🔥 MÓDULO COMBUSTIBLE
                  _buildModuleCard(
                    context,
                    title: 'Gestión de Combustible',
                    icon: Icons.local_gas_station,
                    color: Colors.orange,
                    description:
                        'Registrar y consultar recargas de combustible',
                    actions: [
                      {
                        'label': 'Nueva Recarga',
                        'icon': Icons.add_circle,
                        'onTap': () => _navigateToRecarga(context),
                      },
                      {
                        'label': 'Ver Recargas',
                        'icon': Icons.list_alt,
                        'onTap': () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecargasListScreen(),
                              ),
                            ),
                      },
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🕐 MÓDULO INGRESO/SALIDA
                  _buildModuleCard(
                    context,
                    title: 'Control de Movimientos',
                    icon: Icons.access_time,
                    color: Colors.blue,
                    description: 'Registrar entradas y salidas de maquinaria',
                    actions: [
                      {
                        'label': 'Nuevo Registro',
                        'icon': Icons.add,
                        'onTap': () => _navigateToIngreso(context),
                      },
                      {
                        'label': 'Ver Registros',
                        'icon': Icons.list_alt,
                        'onTap': () => _navigateToIngresosList(context),
                      },
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 📋 MÓDULO REPORTES
                  _buildModuleCard(
                    context,
                    title: 'Reportes de Contratos',
                    icon: Icons.assignment,
                    color: Colors.green,
                    description: 'Crear y consultar reportes de contratos',
                    actions: [
                      {
                        'label': 'Nuevo Reporte',
                        'icon': Icons.add_task,
                        'onTap': () => _navigateToReporte(context),
                      },
                      {
                        'label': 'Ver Reportes',
                        'icon': Icons.list_alt,
                        'onTap': () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ContratosReportesListScreen(),
                              ),
                            ),
                      },
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVA TARJETA DE MÓDULO CON ACCIONES INTEGRADAS
  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> actions,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER DEL MÓDULO
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ BOTONES DE ACCIÓN HORIZONTALES
            Row(
              children: actions.map((action) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: action == actions.last ? 0 : 8,
                      left: action == actions.first ? 0 : 8,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: action['onTap'],
                      icon: Icon(action['icon'], size: 18),
                      label: Text(
                        action['label'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODOS DE NAVEGACIÓN (SIN CAMBIOS)
  void _navigateToRecarga(BuildContext context) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecargaCombustibleScreen(
            usuarioId: _usuarioId,
            usuarioNombre: _usuarioNombre,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Error al abrir recarga: $e');
    }
  }

  void _navigateToIngreso(BuildContext context) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistroScreen(usuarioId: _usuarioId),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Error al abrir ingreso: $e');
    }
  }

  void _navigateToIngresosList(BuildContext context) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IngresosSalidasListScreen(
            usuarioId: _usuarioId,
            usuarioNombre: _usuarioNombre,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(
        context,
        'Error al abrir lista de ingresos/salidas: $e',
      );
    }
  }

  void _navigateToReporte(BuildContext context) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContratoReporteFormScreen(
            usuarioId: _usuarioId,
            usuarioNombre: _usuarioNombre,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Error al abrir reporte: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Cerrar Sesión'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión, $_usuarioNombre?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
