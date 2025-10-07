import 'package:harcha_maquinaria/services/api_client.dart';
import 'package:harcha_maquinaria/services/secure_storage.dart';
import 'package:harcha_maquinaria/services/connectivity_manager.dart';
import 'package:harcha_maquinaria/services/offline_storage_service.dart';
import '../utils/logger.dart';

class DatabaseHelper {
  static final _api = ApiClient();
  static final _connectivityManager = ConnectivityManager();
  static final _offlineStorage = OfflineStorageService();

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
          'pkMaquina': idMaquina,
          'FECHAHORA': fechahora,
          'INGRESO_SALIDA': ingresoSalida,
          'ESTADO_MAQUINA': estadoMaquina ?? 'OPERATIVA',
          'Observaciones': observaciones ?? '',
          'pkUsuario': usuarioId,
        },
      );
      return response['success'] == true;
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerRecargasCombustible({
    int? page,
    int? perPage,
    String? search,
  }) async {
    try {
      // Construir query params
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
          : '';

      final response = await _api.get('/recargas/$queryString');

      // Procesar la respuesta según el nuevo esquema
      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return <String, dynamic>{
          'id': item['id'],
          'codigo': item['codigo'] ?? '',
          'fecha': item['fecha'] ?? '',
          'litros': item['litros'] ?? 0,
          'foto': item['foto'] ?? '',
          'observaciones': item['observaciones'] ?? '',
          'odometro': item['odometro'] ?? 0,
          'kilometros': item['kilometros'] ?? 0,
          'fechahora_recarga': item['fechahora_recarga'] ?? '',
          'patente': item['patente'] ?? '',
          'rut_operador': item['rut_operador'] ?? '',
          'id_recarga_anterior': item['id_recarga_anterior'] ?? '',
          'litros_anterior': item['litros_anterior'] ?? 0,
          'horometro_anterior': item['horometro_anterior'] ?? 0,
          'kilometro_anterior': item['kilometro_anterior'] ?? 0,
          'fecha_anterior': item['fecha_anterior'] ?? '',
          // Datos anidados
          'maquina': item['maquina'] ?? {},
          'usuario': item['usuario'] ?? {},
          'operador': item['operador'] ?? {},
          'obra': item['obra'] ?? {},
          'cliente': item['cliente'] ?? {},
          'usuario_ultima_modificacion':
              item['usuario_ultima_modificacion'] ?? {},
          // Campos adicionales para compatibilidad
          'pkMaquina': item['maquina']?['id'],
          'MAQUINA': item['maquina']?['nombre'] ?? '',
          'pkOperador': item['operador']?['id'],
          'OPERADOR': item['operador']?['usuario'] ?? '',
          'pkUsuario': item['usuario']?['id'],
          'USUARIO': item['usuario']?['usuario'] ?? '',
          'pkObra': item['obra']?['id'],
          'OBRA': item['obra']?['nombre'] ?? '',
          'pkCliente': item['cliente']?['id'],
          'CLIENTE': item['cliente']?['nombre'] ?? '',
        };
      }).toList();
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
    String? rutOperador,
    String? nombreOperador,
    String? foto,
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) async {
    // Verificar conectividad antes de proceder
    final isOnline = await _connectivityManager.checkConnectivity();

    if (isOnline) {
      // Intentar registro online normal
      return await _registrarRecargaOnline(
        idMaquina: idMaquina,
        usuarioId: usuarioId,
        fechahora: fechahora,
        litros: litros,
        obraId: obraId,
        clienteId: clienteId,
        operadorId: operadorId,
        rutOperador: rutOperador,
        nombreOperador: nombreOperador,
        foto: foto,
        observaciones: observaciones,
        odometro: odometro,
        kilometros: kilometros,
        patente: patente,
      );
    } else {
      // Registro offline
      return await _registrarRecargaOffline(
        idMaquina: idMaquina,
        usuarioId: usuarioId,
        fechahora: fechahora,
        litros: litros,
        obraId: obraId,
        clienteId: clienteId,
        operadorId: operadorId,
        rutOperador: rutOperador,
        nombreOperador: nombreOperador,
        observaciones: observaciones,
        odometro: odometro,
        kilometros: kilometros,
        patente: patente,
      );
    }
  }

  /// Método original para registro online (renombrado)
  static Future<Map<String, dynamic>> _registrarRecargaOnline({
    required int idMaquina,
    required int usuarioId,
    required String fechahora,
    required double litros,
    required int obraId,
    required int clienteId,
    int? operadorId,
    String? rutOperador,
    String? nombreOperador,
    String? foto,
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) async {
    try {
      // Obtener datos de la máquina (incluye recarga anterior)
      SafeLogger.debug('Obteniendo datos de máquina ID: $idMaquina');
      final maquinaData = await obtenerMaquinaPorId(idMaquina);
      SafeLogger.debug('Datos de máquina obtenidos', maquinaData);

      // Construir el payload según el nuevo esquema del backend
      final payload = {
        'pkMaquina': idMaquina,
        'pkUsuario': usuarioId,
        'LITROS': litros.toInt(),
        'OBSERVACIONES': observaciones ?? '',
        'ODOMETRO': odometro?.toInt(),
        'KILOMETROS': kilometros?.toInt(),
        'PATENTE': patente ?? '',
        'pkObra': obraId,
        'pkCliente': clienteId,
      };

      // Agregar operador si existe
      if (operadorId != null) {
        payload['pkOperador'] = operadorId;
        if (rutOperador != null && rutOperador.isNotEmpty) {
          payload['RUT_OPERADOR'] = rutOperador;
        }
        if (nombreOperador != null && nombreOperador.isNotEmpty) {
          payload['OPERADOR'] = nombreOperador;
        }
        SafeLogger.debug(
            'Datos de operador agregados - ID: $operadorId, RUT: $rutOperador, Nombre: $nombreOperador');
      }

      // Agregar datos de recarga anterior si existen
      if (maquinaData['pkUltima_recarga'] != null) {
        payload['pkRecarga_anterior'] = maquinaData['pkUltima_recarga'];
        payload['ID_Recarga_Anterior'] = maquinaData['ID_Ultima_Recarga'] ?? '';
        payload['Litros_Anterior'] = maquinaData['Litros_Ultima'] ?? 0;
        payload['Horometro_Anterior'] = maquinaData['HR_Actual'] ?? 0;
        payload['Kilometro_Anterior'] = maquinaData['KM_Actual'] ?? 0;
        payload['Fecha_Anterior'] = maquinaData['Fecha_Ultima'] ?? '';
        SafeLogger.debug('Datos de recarga anterior agregados al payload');
      } else {
        SafeLogger.debug('No hay datos de recarga anterior para esta máquina');
      }

      SafeLogger.debug('Payload a enviar', payload);
      final response = await _api.post('/recargas/', body: payload);
      SafeLogger.debug('Respuesta del servidor', response);
      return response;
    } catch (e) {
      SafeLogger.error('Error al registrar recarga', e);
      throw Exception('Error al registrar recarga: $e');
    }
  }

  /// Método para registro offline
  static Future<Map<String, dynamic>> _registrarRecargaOffline({
    required int idMaquina,
    required int usuarioId,
    required String fechahora,
    required double litros,
    required int obraId,
    required int clienteId,
    int? operadorId,
    String? rutOperador,
    String? nombreOperador,
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) async {
    try {
      SafeLogger.info(
          'Guardando recarga offline - Máquina: $idMaquina, Litros: $litros');

      final uuid = await _offlineStorage.saveRecargaOffline(
        idMaquina: idMaquina,
        usuarioId: usuarioId,
        fechahora: fechahora,
        litros: litros,
        obraId: obraId,
        clienteId: clienteId,
        operadorId: operadorId,
        rutOperador: rutOperador,
        nombreOperador: nombreOperador,
        observaciones: observaciones,
        odometro: odometro,
        kilometros: kilometros,
        patente: patente,
      );

      return {
        'success': true,
        'message': 'Recarga guardada offline correctamente',
        'codigo_recarga': uuid,
        'offline': true,
      };
    } catch (e) {
      SafeLogger.error('Error al guardar recarga offline', e);
      throw Exception('Error al guardar recarga offline: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerMaquinas() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        // Online: obtener desde API y actualizar caché
        final response = await _api.get('/maquinas/');
        final List<dynamic> rawData = response['data'] ?? [];
        final maquinas = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkMaquina': item['pkMaquina'],
            'MAQUINA': item['MAQUINA'] ?? '',
            'MARCA': item['MARCA'] ?? '',
            'MODELO': item['MODELO'] ?? '',
            'PATENTE': item['PATENTE'] ?? '',
            'ESTADO': item['ESTADO'] ?? '',
            'ID_MAQUINA': item['ID_MAQUINA'] ?? '',
            'CODIGO_MAQUINA': item['CODIGO_MAQUINA']?.toString() ?? '',
            'HR_ACTUAL': item['HR_Actual'],
            'KM_ACTUAL': item['KM_Actual'],
            'OPERADORES': item['OPERADORES'] ?? [],
            'OBSERVACIONES': item['OBSERVACIONES']?.toString() ?? '',
            'FECHA_CREACION': item['FECHA_CREACION'],
            'FECHA_ACTUALIZACION': item['FECHA_ACTUALIZACION'],
          };
        }).toList();

        // Guardar en caché
        await _offlineStorage.cacheMaquinas(maquinas);
        SafeLogger.info(
            'Máquinas obtenidas online y cacheadas: ${maquinas.length}');

        return maquinas;
      } else {
        // Offline: obtener desde caché
        final cachedMaquinas = await _offlineStorage.getCachedMaquinas();
        SafeLogger.info(
            'Máquinas obtenidas desde caché: ${cachedMaquinas.length}');
        return cachedMaquinas;
      }
    } catch (e) {
      // Si falla online, intentar caché como fallback
      SafeLogger.warning('Error al obtener máquinas online, usando caché', e);
      final cachedMaquinas = await _offlineStorage.getCachedMaquinas();
      if (cachedMaquinas.isEmpty) {
        throw Exception('No hay datos disponibles offline');
      }
      return cachedMaquinas;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerObras() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/obras/');
        final List<dynamic> rawData = response['data'] ?? [];
        final obras = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkObra': item['pkObra'] ?? item['id'],
            'ID_OBRA': item['ID_OBRA'] ?? item['id_obra'] ?? '',
            'NOMBRE': item['NOMBRE'] ?? item['nombre'] ?? '',
            'DIRECCION': item['DIRECCION'] ?? item['direccion'] ?? '',
            'nombre': item['nombre'] ?? item['NOMBRE'] ?? '',
          };
        }).toList();

        await _offlineStorage.cacheObras(obras);
        SafeLogger.info('Obras obtenidas online y cacheadas: ${obras.length}');
        return obras;
      } else {
        final cachedObras = await _offlineStorage.getCachedObras();
        SafeLogger.info('Obras obtenidas desde caché: ${cachedObras.length}');
        return cachedObras;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener obras online, usando caché', e);
      final cachedObras = await _offlineStorage.getCachedObras();
      if (cachedObras.isEmpty) {
        throw Exception('No hay datos disponibles offline');
      }
      return cachedObras;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerClientes() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/clientes/');
        final List<dynamic> rawData = response['data'] ?? [];
        final clientes = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkCliente': item['pkCliente'] ?? item['id'],
            'ID_CLIENTE': item['ID_CLIENTE'] ?? item['id_cliente'] ?? '',
            'CLIENTE': item['CLIENTE'] ?? item['nombre'] ?? '',
            'RUT': item['RUT'] ?? item['rut'] ?? '',
            'nombre': item['nombre'] ?? item['CLIENTE'] ?? '',
          };
        }).toList();

        await _offlineStorage.cacheClientes(clientes);
        SafeLogger.info(
            'Clientes obtenidos online y cacheados: ${clientes.length}');
        return clientes;
      } else {
        final cachedClientes = await _offlineStorage.getCachedClientes();
        SafeLogger.info(
            'Clientes obtenidos desde caché: ${cachedClientes.length}');
        return cachedClientes;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener clientes online, usando caché', e);
      final cachedClientes = await _offlineStorage.getCachedClientes();
      if (cachedClientes.isEmpty) {
        throw Exception('No hay datos disponibles offline');
      }
      return cachedClientes;
    }
  }

  static Future<Map<String, dynamic>> obtenerMaquinaPorId(int maquinaId) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        // Online: obtener desde API
        final response = await _api.get('/maquinas/$maquinaId');

        if (response['success'] == true) {
          final data = response['data'];
          final maquinaData = <String, dynamic>{
            'pkMaquina': data['pkMaquina'],
            'MAQUINA': data['MAQUINA'] ?? '',
            'MARCA': data['MARCA'] ?? '',
            'MODELO': data['MODELO'] ?? '',
            'PATENTE': data['PATENTE'] ?? '',
            'ESTADO': data['ESTADO'] ?? '',
            'ID_MAQUINA': data['ID_MAQUINA'] ?? '',
            'CODIGO_MAQUINA': data['CODIGO_MAQUINA']?.toString() ?? '',
            'HR_Actual': data['HR_Actual'],
            'KM_Actual': data['KM_Actual'],
            'OPERADORES': data['OPERADORES'] ?? [],
            'OBSERVACIONES': data['OBSERVACIONES']?.toString() ?? '',
            'FECHA_CREACION': data['FECHA_CREACION'],
            'FECHA_ACTUALIZACION': data['FECHA_ACTUALIZACION'],
            // Datos de última recarga
            'pkUltima_recarga': data['pkUltima_recarga'],
            'ID_Ultima_Recarga': data['ID_Ultima_Recarga'],
            'Litros_Ultima': data['Litros_Ultima'],
            'Fecha_Ultima': data['Fecha_Ultima'],
          };

          // Cachear la máquina individual
          await _offlineStorage.cacheMaquinas([maquinaData]);
          SafeLogger.info('Máquina $maquinaId obtenida online y cacheada');

          return maquinaData;
        }

        throw Exception('No se encontró la máquina');
      } else {
        // Offline: buscar en caché
        final cachedMaquinas = await _offlineStorage.getCachedMaquinas();
        final maquina = cachedMaquinas.firstWhere(
          (m) => m['pkMaquina'] == maquinaId,
          orElse: () => throw Exception('Máquina no encontrada en caché'),
        );

        SafeLogger.info('Máquina $maquinaId obtenida desde caché');
        return maquina;
      }
    } catch (e) {
      SafeLogger.error('Error al obtener máquina $maquinaId', e);

      // Fallback: intentar caché si falla online
      try {
        final cachedMaquinas = await _offlineStorage.getCachedMaquinas();
        final maquina = cachedMaquinas.firstWhere(
          (m) => m['pkMaquina'] == maquinaId,
          orElse: () => throw Exception('Máquina no disponible offline'),
        );

        SafeLogger.warning(
            'Usando caché como fallback para máquina $maquinaId');
        return maquina;
      } catch (cacheError) {
        throw Exception('Error al obtener máquina: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerOperadoresMaquina(
      int maquinaId) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/maquinas/$maquinaId/operadores');

        if (response['success'] == true) {
          final List<dynamic> rawData = response['data'] ?? [];
          final operadores = rawData.map<Map<String, dynamic>>((item) {
            return <String, dynamic>{
              'id': item['id'] ?? item['pkUsuario'],
              'pkUsuario': item['pkUsuario'] ?? item['id'],
              'nombre':
                  item['nombre'] ?? item['usuario'] ?? item['NOMBREUSUARIO'],
              'usuario': item['usuario'] ?? item['nombre'],
              'NOMBREUSUARIO': item['NOMBREUSUARIO'] ?? item['nombre'],
              'RUT': item['RUT'] ?? '',
            };
          }).toList();

          await _offlineStorage.cacheOperadoresMaquina(maquinaId, operadores);
          SafeLogger.info(
              'Operadores de máquina $maquinaId cacheados: ${operadores.length}');
          return operadores;
        }
        return [];
      } else {
        final cachedOperadores =
            await _offlineStorage.getCachedOperadoresMaquina(maquinaId);
        SafeLogger.info(
            'Operadores obtenidos desde caché: ${cachedOperadores.length}');
        return cachedOperadores;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener operadores online, usando caché', e);
      final cachedOperadores =
          await _offlineStorage.getCachedOperadoresMaquina(maquinaId);
      return cachedOperadores;
    }
  }

  static Future<Map<String, dynamic>> obtenerOperadorPorId(
      int operadorId) async {
    try {
      final response = await _api.get('/auth/usuarios/$operadorId');

      if (response['success'] == true) {
        final data = response['data'];
        return <String, dynamic>{
          'id': data['pkUsuario'],
          'RUT': data['RUT']?.toString() ?? '',
          'nombre': data['NOMBREUSUARIO']?.toString() ?? '',
          'usuario': data['USUARIO']?.toString() ?? '',
          'NOMBREUSUARIO': data['NOMBREUSUARIO']?.toString() ?? '',
        };
      }

      throw Exception('No se encontró el operador');
    } catch (e) {
      SafeLogger.error('ERROR obteniendo operador $operadorId', e);
      throw Exception('Error al obtener operador: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerContratosPorMaquina(
    int maquinaId,
  ) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        // Online: obtener desde API y cachear
        final response = await _api.get('/contratos/?maquina_id=$maquinaId');
        final List<dynamic> rawData = response['data'] ?? [];
        final contratos = rawData.map<Map<String, dynamic>>((item) {
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

        // Cachear contratos de la máquina
        await _offlineStorage.cacheContratosMaquina(maquinaId, contratos);
        SafeLogger.info(
            'Contratos de máquina $maquinaId cacheados: ${contratos.length}');

        return contratos;
      } else {
        // Offline: obtener desde caché
        final cachedContratos =
            await _offlineStorage.getCachedContratosMaquina(maquinaId);
        SafeLogger.info(
            'Contratos obtenidos desde caché: ${cachedContratos.length}');
        return cachedContratos;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener contratos online, usando caché', e);
      final cachedContratos =
          await _offlineStorage.getCachedContratosMaquina(maquinaId);
      if (cachedContratos.isEmpty) {
        throw Exception(
            'No hay contratos disponibles offline para esta máquina');
      }
      return cachedContratos;
    }
  }

  static Future<Map<String, dynamic>> obtenerContratosReportes({
    int? limit,
    int page = 1,
    String search = '',
  }) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        // Online: obtener desde API
        String endpoint = '/contratos_reportes/?page=$page';

        if (limit != null) {
          endpoint += '&limit=$limit';
        }

        if (search.isNotEmpty) {
          endpoint += '&search=${Uri.encodeComponent(search)}';
        }

        final response = await _api.get(endpoint);

        // Cachear los reportes
        if (response['data'] != null) {
          await _offlineStorage.cacheContratosReportes(
              List<Map<String, dynamic>>.from(response['data']));
          SafeLogger.info('Reportes cacheados correctamente');
        }

        return response;
      } else {
        // Offline: obtener desde caché
        final cachedReportes =
            await _offlineStorage.getCachedContratosReportes();

        // Simular paginación offline
        final startIndex = (page - 1) * (limit ?? 20);
        final endIndex = startIndex + (limit ?? 20);

        // Filtrar por búsqueda si existe
        var filteredReportes = cachedReportes;
        if (search.isNotEmpty) {
          filteredReportes = cachedReportes.where((reporte) {
            final searchLower = search.toLowerCase();
            return (reporte['ID_REPORTE']
                        ?.toString()
                        .toLowerCase()
                        .contains(searchLower) ??
                    false) ||
                (reporte['MAQUINA']
                        ?.toString()
                        .toLowerCase()
                        .contains(searchLower) ??
                    false) ||
                (reporte['CONTRATO']
                        ?.toString()
                        .toLowerCase()
                        .contains(searchLower) ??
                    false);
          }).toList();
        }

        final paginatedReportes = filteredReportes.sublist(
          startIndex.clamp(0, filteredReportes.length),
          endIndex.clamp(0, filteredReportes.length),
        );

        SafeLogger.info(
            'Reportes obtenidos desde caché: ${paginatedReportes.length}');

        return {
          'success': true,
          'data': paginatedReportes,
          'pagination': {
            'page': page,
            'per_page': limit ?? 20,
            'total': filteredReportes.length,
            'total_pages': (filteredReportes.length / (limit ?? 20)).ceil(),
          },
          'offline': true, // Indicador de que viene de caché
        };
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener reportes online, usando caché', e);

      // Fallback a caché
      final cachedReportes = await _offlineStorage.getCachedContratosReportes();
      if (cachedReportes.isEmpty) {
        throw Exception('No hay reportes disponibles offline');
      }

      return {
        'success': true,
        'data': cachedReportes,
        'offline': true,
      };
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
    // Verificar conectividad
    final isOnline = await _connectivityManager.checkConnectivity();

    if (isOnline) {
      // Intentar registro online
      return await _registrarReporteOnline(
        fechaReporte: fechaReporte,
        pkMaquina: pkMaquina,
        maquinaTxt: maquinaTxt,
        pkContrato: pkContrato,
        contratoTxt: contratoTxt,
        odometroInicial: odometroInicial,
        odometroFinal: odometroFinal,
        horasTrabajadas: horasTrabajadas,
        horasMinimas: horasMinimas,
        kmInicial: kmInicial,
        kmFinal: kmFinal,
        kilometros: kilometros,
        trabajoRealizado: trabajoRealizado,
        estadoReporte: estadoReporte,
        observaciones: observaciones,
        incidente: incidente,
        foto1: foto1,
        foto2: foto2,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
      );
    } else {
      // Registro offline
      return await _registrarReporteOffline(
        fechaReporte: fechaReporte,
        pkMaquina: pkMaquina,
        maquinaTxt: maquinaTxt,
        pkContrato: pkContrato,
        contratoTxt: contratoTxt,
        odometroInicial: odometroInicial,
        odometroFinal: odometroFinal,
        horasTrabajadas: horasTrabajadas,
        horasMinimas: horasMinimas,
        kmInicial: kmInicial,
        kmFinal: kmFinal,
        kilometros: kilometros,
        trabajoRealizado: trabajoRealizado,
        estadoReporte: estadoReporte,
        observaciones: observaciones,
        incidente: incidente,
        foto1: foto1,
        foto2: foto2,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
      );
    }
  }

  /// Registro online de reporte
  static Future<Map<String, dynamic>> _registrarReporteOnline({
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
      SafeLogger.error('Error al registrar reporte online', e);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Registro offline de reporte
  static Future<Map<String, dynamic>> _registrarReporteOffline({
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
      SafeLogger.info('Guardando reporte offline - Contrato: $pkContrato');

      final idReporte = _generateReporteId();

      final uuid = await _offlineStorage.saveReporteOffline(
        idReporte: idReporte,
        fechaReporte: fechaReporte,
        pkMaquina: pkMaquina,
        maquinaTxt: maquinaTxt,
        pkContrato: pkContrato,
        contratoTxt: contratoTxt,
        odometroInicial: odometroInicial,
        odometroFinal: odometroFinal,
        horasTrabajadas: horasTrabajadas,
        horasMinimas: horasMinimas,
        kmInicial: kmInicial,
        kmFinal: kmFinal,
        kilometros: kilometros,
        trabajoRealizado: trabajoRealizado,
        estadoReporte: estadoReporte,
        observaciones: observaciones,
        incidente: incidente,
        foto1: foto1,
        foto2: foto2,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
      );

      return {
        'success': true,
        'message': 'Reporte guardado offline correctamente',
        'id_reporte': idReporte,
        'uuid': uuid,
        'offline': true,
      };
    } catch (e) {
      SafeLogger.error('Error al guardar reporte offline', e);
      return {
        'success': false,
        'message': 'Error al guardar reporte offline: $e'
      };
    }
  }

  static Future<String> obtenerReciboRecargaHtml(int recargaId) async {
    try {
      final response = await _api.get(
        '/recargas/$recargaId/recibo',
        extraHeaders: {
          'Accept': 'text/html', // Forzamos que el backend devuelva HTML
        },
      );

      SafeLogger.info('Tipo de respuesta: ${response.runtimeType}');
      SafeLogger.info(
          'Contenido de respuesta (primeros 200 chars): ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}');

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

  ///Obtener todos los contratos (sin filtrar por máquina)
  static Future<List<Map<String, dynamic>>> obtenerContratos() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        // Online: obtener desde API y cachear
        final response = await _api.get('/contratos/');
        final List<dynamic> rawData = response['data'] ?? [];
        final contratos = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'id': item['id'],
            'pkContrato': item['id'], // Alias para compatibilidad
            'id_contrato': item['id_contrato'] ?? '',
            'nombre': item['nombre'] ?? '',
            'NOMBRE_CONTRATO': item['nombre'] ?? '', // Alias
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

        // Cachear contratos globales
        await _offlineStorage.cacheContratos(contratos);
        SafeLogger.info('Contratos globales cacheados: ${contratos.length}');

        return contratos;
      } else {
        // Offline: obtener desde caché
        final cachedContratos = await _offlineStorage.getCachedContratos();
        SafeLogger.info(
            'Contratos obtenidos desde caché: ${cachedContratos.length}');
        return cachedContratos;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener contratos online, usando caché', e);
      final cachedContratos = await _offlineStorage.getCachedContratos();
      if (cachedContratos.isEmpty) {
        throw Exception('No hay contratos disponibles offline');
      }
      return cachedContratos;
    }
  }
}
