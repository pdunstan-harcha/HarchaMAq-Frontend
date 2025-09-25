import 'package:harcha_maquinaria/services/api_client.dart';
import 'package:harcha_maquinaria/services/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

class DatabaseHelper {
  static final _api = ApiClient();

  static Future<Map<String, dynamic>?> login(
    String usuario,
    String password,
  ) async {
    try {
      final response = await _api.post(
        '/auth/login',
        body: {'username': usuario, 'password': password},
      );

      if (response['success'] == true) {
        await SecureStorage.saveToken(response['access_token']);
        await SecureStorage.saveRefreshToken(response['refresh_token']);
        return response;
      }
      return null;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static String _generateReporteId() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // 25 para 2025
    final month = now.month.toString().padLeft(2, '0'); // 09 para septiembre
    final day = now.day.toString().padLeft(2, '0'); // 24 para hoy
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'RDC$year$month$day$hour$minute$second';
  }

  static Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await SecureStorage.clearAll();
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerIngresosSalidas() async {
    try {
      final response = await _api.get('/ingresos_salidas/');

      // Procesar la respuesta con la nueva estructura del backend
      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          // Datos principales del movimiento
          'id': item['id'],
          'codigo': item['codigo'] ?? '',
          'fechahora': item['fechahora'] ?? '',
          'ingreso_salida': item['ingreso_salida'] ?? '',
          'tiempo': item['tiempo'],
          'tiempo_formateado': item['tiempo_formateado'] ?? '',
          'fechahora_ultimo': item['fechahora_ultimo'],
          'estado_maquina': item['estado_maquina'],
          'observaciones': item['observaciones'],
          'usuario_id': item['usuario_id'],

          // Datos de la máquina (con JOIN)
          'maquina_id': item['maquina_id'],
          'maquina': item['maquina'] ?? '',
          'maquina_codigo': item['maquina_codigo'] ?? '',

          // Datos adicionales
          'usuario_nombre': item['usuario_nombre'],
          'editar_fecha': item['editar_fecha'],
          'fecha_editada': item['fecha_editada'],
          'puede_modificar_fecha': item['puede_modificar_fecha'] ?? false,
          'movimiento_anterior_texto': item['movimiento_anterior_texto'],
        };
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener ingresos/salidas', e);
      if (e.toString().contains('500') ||
          e.toString().contains('Internal Server Error')) {
        throw Exception(
            'Error temporal del servidor. Intente nuevamente en unos momentos.');
      }
      throw Exception('Error al obtener ingresos/salidas: $e');
    }
  }

  // Método con soporte para paginación
  static Future<Map<String, dynamic>> obtenerIngresosSalidasPaginado({
    int page = 1,
    int perPage = 20,
    String search = '',
  }) async {
    try {
      String endpoint = '/ingresos_salidas/?page=$page&per_page=$perPage';

      if (search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await _api.get(endpoint);

      // Procesar los datos con la estructura actualizada
      final List<dynamic> rawData = response['data'] ?? [];
      final processedData = rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          // Datos principales del movimiento (campos originales del CSV)
          'id': item['id'],
          'codigo': item['codigo'] ?? '',
          'FECHAHORA': item['fechahora'] ?? '', // Mapeo al nombre original
          'INGRESO_SALIDA':
              item['ingreso_salida'] ?? '', // Mapeo al nombre original
          'TIEMPO': item['tiempo'], // TIEMPO TRANSCURRIDO original
          'tiempo_formateado': item['tiempo_formateado'] ?? '',
          'FECHAHORA_ULTIMO':
              item['fechahora_ultimo'], // Mapeo al nombre original
          'ESTADO_MAQUINA': item['estado_maquina'], // NUEVO ESTADO original
          'Observaciones': item['observaciones'], // Mapeo al nombre original
          'USUARIO_ID': item['usuario_id'], // Mapeo al nombre original

          // Datos de la máquina (con JOIN)
          'maquina_id': item['maquina_id'],
          'MAQUINA': item['maquina'] ?? '', // Mapeo al nombre original
          'maquina_codigo': item['maquina_codigo'] ?? '',

          // Datos adicionales
          'usuario_nombre': item['usuario_nombre'],
          'editar_fecha': item['editar_fecha'],
          'fecha_editada': item['fecha_editada'],
          'puede_modificar_fecha': item['puede_modificar_fecha'] ?? false,
          'movimiento_anterior_texto': item['movimiento_anterior_texto'],
        };
      }).toList();

      return {
        'success': response['success'] ?? true,
        'data': processedData,
        'pagination': response['pagination'] ?? {},
      };
    } catch (e) {
      SafeLogger.error('Error al obtener ingresos/salidas paginado', e);
      if (e.toString().contains('500') ||
          e.toString().contains('Internal Server Error')) {
        throw Exception(
            'Error temporal del servidor. Intente nuevamente en unos momentos.');
      }
      throw Exception('Error al obtener ingresos/salidas paginado: $e');
    }
  }

  static Future<bool> registrarIngresoSalida({
    required int idMaquina,
    required String fechahora,
    required String ingresoSalida,
    String? estadoMaquina,
    String? observaciones,
    required int usuarioId,
  }) async {
    try {
      final response = await _api.post(
        '/ingresos_salidas/',
        body: {
          'pkMaquina': idMaquina, // Backend espera pkMaquina
          'FECHAHORA': fechahora,
          'INGRESO_SALIDA': ingresoSalida,
          'ESTADO_MAQUINA':
              estadoMaquina ?? 'OPERATIVA', // Valor por defecto válido
          'Observaciones': observaciones ?? '', // Convertir null a string vacía
          'pkUsuario': usuarioId, // Backend espera pkUsuario
        },
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerRecargasCombustible() async {
    try {
      final response = await _api.get('/recargas/');
      return List<Map<String, dynamic>>.from(response['data'] ?? response);
    } catch (e) {
      throw Exception('Error al obtener recargas: $e');
    }
  }

  static Future<Map<String, dynamic>> registrarRecargaCombustible({
    required int idMaquina,
    required int usuarioId,
    required String fechahora,
    required double litros,
    required int obraId,
    required int clienteId,
    int? operadorId,
    String? foto,
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) async {
    try {
      final response = await _api.post(
        '/recargas/',
        body: {
          'pkMaquina': idMaquina, // Backend espera pkMaquina
          'pkUsuario': usuarioId, // Backend espera pkUsuario
          'OPERADOR_ID': operadorId,
          'FECHAHORA': fechahora,
          'LITROS': litros,
          'OBRA_ID': obraId,
          'CLIENTE_ID': clienteId,
          'FOTO': foto ?? '', // Convertir null a string vacía
          'OBSERVACIONES': observaciones ?? '', // Convertir null a string vacía
          'ODOMETRO': odometro,
          'KILOMETROS': kilometros,
          'PATENTE': patente ?? '', // Convertir null a string vacía
        },
      );
      return response;
    } catch (e) {
      throw Exception('Error al registrar recarga: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerMaquinas() async {
    try {
      final response = await _api.get('/maquinas/');

      // Procesar la respuesta manejando valores null
      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          'pkMaquina': item['pkMaquina'],
          'MAQUINA': item['MAQUINA'] ?? '',
          'MARCA': item['MARCA'] ?? '',
          'MODELO': item['MODELO'] ?? '',
          'PATENTE': item['PATENTE'] ?? '',
          'ESTADO': item['ESTADO'] ?? '',
          'ID_MAQUINA': item['ID_MAQUINA'] ?? '',
          'CODIGO_MAQUINA': item['CODIGO_MAQUINA'].toString() ?? '',
          'HR_ACTUAL': item['HR_Actual'],
          'KM_ACTUAL': item['KM_Actual'],
          'OPERADORES': item['OPERADORES'] ?? [],
          'OBSERVACIONES': item['OBSERVACIONES'].toString() ?? '',
          'FECHA_CREACION': item['FECHA_CREACION'],
          'FECHA_ACTUALIZACION': item['FECHA_ACTUALIZACION'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener máquinas: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerContratos() async {
    try {
      final response = await _api.get('/contratos/');
      return List<Map<String, dynamic>>.from(response['data'] ?? response);
    } catch (e) {
      throw Exception('Error al obtener contratos: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerOperadoresMaquina(
      int maquinaId) async {
    try {
      final response = await _api.get('/maquinas/$maquinaId/operadores');

      if (response['success'] == true) {
        final List<dynamic> rawData = response['data'] ?? [];
        return rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'id': item['id'],
            'usuario': item['usuario']?.toString() ?? '',
            'usuario_id': item['usuario_id']?.toString() ?? '',
            'nombre': item['nombre']?.toString() ?? '',
            'nombre_completo': item['nombre_completo']?.toString() ?? '',
          };
        }).toList();
      }

      return [];
    } catch (e) {
      SafeLogger.error('ERROR obteniendo operadores de máquina $maquinaId', e);
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerContratosPorMaquina(
    int maquinaId,
  ) async {
    try {
      final response = await _api.get('/contratos/?maquina_id=$maquinaId');

      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          'id': item['id'],
          'id_contrato': item['id_contrato'] ?? '',
          'nombre': item['nombre'] ?? '',
          'pk_maquina': item['pk_maquina'],
          'pk_cliente': item['pk_cliente'],
          'pk_obra': item['pk_obra'],
          'fecha_inicio': item['fecha_inicio'],
          'estado': item['estado'] ?? '',
          'maquina_nombre': item['maquina_nombre'] ?? '',
          'cliente_nombre': item['cliente_nombre'] ?? '',
          'obra_nombre': item['obra_nombre'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener contratos por máquina: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerObras() async {
    try {
      final response = await _api.get('/obras/');

      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          'pkObra': item['pkObra'] ?? item['id'],
          'ID_OBRA': item['ID_OBRA'] ?? item['id_obra'] ?? '',
          'OBRA': item['OBRA'] ?? item['nombre'] ?? '',
          'nombre': item['nombre'] ?? item['OBRA'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener obras: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerClientes() async {
    try {
      final response = await _api.get('/clientes/');

      // Procesar la respuesta manejando valores null
      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          'pkCliente': item['pkCliente'] ?? item['id'],
          'ID_CLIENTE': item['ID_CLIENTE'] ?? item['id_cliente'] ?? '',
          'CLIENTE': item['CLIENTE'] ?? item['nombre'] ?? '',
          'RUT': item['RUT'] ?? item['rut'] ?? '',
          'nombre': item['nombre'] ?? item['CLIENTE'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  static Future<Map<String, dynamic>> obtenerContratosReportes({
    int? limit,
    int page = 1,
    String search = '',
  }) async {
    try {
      String endpoint = '/contratos_reportes/?page=$page';

      if (limit != null) {
        endpoint += '&limit=$limit';
      }

      if (search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await _api.get(endpoint);
      return response;
    } catch (e) {
      throw Exception('Error al obtener reportes: $e');
    }
  }

  static Future<Map<String, dynamic>> registrarContratoReporte({
    required String fechaReporte,
    required int pkMaquina,
    required String maquinaTxt,
    required int pkContrato,
    required String contratoTxt,
    required double odometroInicial,
    required double odometroFinal,
    required double horasTrabajadas,
    required double horasMinimas,
    required double kmInicial,
    required double kmFinal,
    required double kilometros,
    required String trabajoRealizado,
    required String estadoReporte,
    required String observaciones,
    required String incidente,
    String? foto1,
    String? foto2,
    required int usuarioId,
    required String usuarioNombre,
  }) async {
    try {
      final response = await _api.post(
        '/contratos_reportes/',
        body: {
          'ID_REPORTE': _generateReporteId(),
          'FECHA_REPORTE': fechaReporte,
          'pkMaquina': pkMaquina,
          'MAQUINA': maquinaTxt,
          'pkContrato': pkContrato,
          'CONTRATO': contratoTxt,
          'ODOMETRO_INICIAL': odometroInicial,
          'ODOMETRO_FINAL': odometroFinal,
          'HORAS_TRABAJADAS': horasTrabajadas,
          'HORAS_MINIMAS': horasMinimas,
          'KM_INICIAL': kmInicial,
          'KM_FINAL': kmFinal,
          'KILOMETROS': kilometros,
          'TRABAJO_REALIZADO': trabajoRealizado,
          'ESTADO_REPORTE': estadoReporte,
          'OBSERVACIONES': observaciones,
          'INCIDENTE': incidente,
          'FOTO1': foto1,
          'FOTO2': foto2,
          'pkUsuario': usuarioId,
          'USUARIO': usuarioNombre,
        },
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<String> obtenerReciboRecargaHtml(String recargaId) async {
    try {
      final response = await _api.get(
        '/recargas/$recargaId/recibo',
        extraHeaders: {
          'Accept': 'text/html', // Forzamos que el backend devuelva HTML
        },
      );

      if (response is String && response.isNotEmpty) {
        return response;
      } else if (response['success'] == false) {
        throw Exception('Error desde backend: ${response['message']}');
      } else {
        throw Exception('Respuesta inválida al obtener recibo.');
      }
    } catch (e) {
      SafeLogger.error('Error al obtener recibo de recarga $recargaId', e);
      throw Exception('Error al obtener recibo: $e');
    }
  }
}
