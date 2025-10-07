import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/logger.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance =
      OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  Database? _database;

  /// Inicializa la base de datos SQLite
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'harcha_offline.db');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      SafeLogger.error('Error al inicializar base de datos offline', e);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE reportes_offline (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
          id_reporte TEXT NOT NULL,
          fecha_reporte TEXT NOT NULL,
          pk_maquina INTEGER NOT NULL,
          maquina_txt TEXT NOT NULL,
          pk_contrato INTEGER NOT NULL,
          contrato_txt TEXT NOT NULL,
          odometro_inicial REAL NOT NULL,
          odometro_final REAL NOT NULL,
          horas_trabajadas REAL NOT NULL,
          horas_minimas REAL NOT NULL,
          km_inicial REAL NOT NULL,
          km_final REAL NOT NULL,
          kilometros REAL NOT NULL,
          trabajo_realizado TEXT NOT NULL,
          estado_reporte TEXT NOT NULL,
          observaciones TEXT,
          incidente TEXT,
          foto1 TEXT,
          foto2 TEXT,
          usuario_id INTEGER NOT NULL,
          usuario_nombre TEXT NOT NULL,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TEXT
        )
      ''');
      SafeLogger.info(
          'Base de datos migrada a versión 2 - Tabla reportes_offline creada');
    }
  }

  /// Crea las tablas necesarias
  Future<void> _createTables(Database db, int version) async {
    try {
      // Tabla para recargas de combustible offline
      await db.execute('''
        CREATE TABLE recargas_offline (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
          id_maquina INTEGER NOT NULL,
          usuario_id INTEGER NOT NULL,
          operador_id INTEGER,
          rut_operador TEXT,
          nombre_operador TEXT,
          fechahora TEXT NOT NULL,
          litros REAL NOT NULL,
          obra_id INTEGER NOT NULL,
          cliente_id INTEGER NOT NULL,
          observaciones TEXT,
          odometro REAL,
          kilometros REAL,
          patente TEXT,
          datos_adicionales TEXT,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TEXT
        )
      ''');

      // Tabla para datos de referencia (máquinas, obras, clientes)
      await db.execute('''
        CREATE TABLE reportes_offline (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
          id_reporte TEXT NOT NULL,
          fecha_reporte TEXT NOT NULL,
          pk_maquina INTEGER NOT NULL,
          maquina_txt TEXT NOT NULL,
          pk_contrato INTEGER NOT NULL,
          contrato_txt TEXT NOT NULL,
          odometro_inicial REAL NOT NULL,
          odometro_final REAL NOT NULL,
          horas_trabajadas REAL NOT NULL,
          horas_minimas REAL NOT NULL,
          km_inicial REAL NOT NULL,
          km_final REAL NOT NULL,
          kilometros REAL NOT NULL,
          trabajo_realizado TEXT NOT NULL,
          estado_reporte TEXT NOT NULL,
          observaciones TEXT,
          incidente TEXT,
          foto1 TEXT,
          foto2 TEXT,
          usuario_id INTEGER NOT NULL,
          usuario_nombre TEXT NOT NULL,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE datos_referencia (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          datos TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      SafeLogger.info('Tablas de base de datos offline creadas exitosamente');
    } catch (e) {
      SafeLogger.error('Error al crear tablas de base de datos', e);
      rethrow;
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

  /// Guarda una recarga de combustible offline
  Future<String> saveRecargaOffline({
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
    Map<String, dynamic>? datosAdicionales,
  }) async {
    try {
      final db = await database;
      final uuid = _generateReporteId();
      final now = DateTime.now().toIso8601String();

      await db.insert('recargas_offline', {
        'uuid': uuid,
        'id_maquina': idMaquina,
        'usuario_id': usuarioId,
        'operador_id': operadorId,
        'rut_operador': rutOperador,
        'nombre_operador': nombreOperador,
        'fechahora': fechahora,
        'litros': litros,
        'obra_id': obraId,
        'cliente_id': clienteId,
        'observaciones': observaciones,
        'odometro': odometro,
        'kilometros': kilometros,
        'patente': patente,
        'datos_adicionales':
            datosAdicionales != null ? jsonEncode(datosAdicionales) : null,
        'created_at': now,
      });

      SafeLogger.info('Recarga guardada offline con UUID: $uuid');
      return uuid;
    } catch (e) {
      SafeLogger.error('Error al guardar recarga offline', e);
      rethrow;
    }
  }

  /// Obtiene todas las recargas pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingRecargas() async {
    try {
      final db = await database;
      final result = await db.query(
        'recargas_offline',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return result.map((row) {
        final map = Map<String, dynamic>.from(row);
        if (map['datos_adicionales'] != null) {
          map['datos_adicionales'] = jsonDecode(map['datos_adicionales']);
        }
        return map;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener recargas pendientes', e);
      return [];
    }
  }

  /// Marca una recarga como sincronizada
  Future<void> markRecargaAsSynced(String uuid,
      {String? serverResponse}) async {
    try {
      final db = await database;
      await db.update(
        'recargas_offline',
        {
          'synced': 1,
          'last_sync_attempt': DateTime.now().toIso8601String(),
        },
        where: 'uuid = ?',
        whereArgs: [uuid],
      );

      SafeLogger.info('Recarga marcada como sincronizada: $uuid');
    } catch (e) {
      SafeLogger.error('Error al marcar recarga como sincronizada', e);
    }
  }

  /// Incrementa el contador de intentos de sincronización
  Future<void> incrementSyncAttempts(String uuid) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE recargas_offline SET sync_attempts = sync_attempts + 1, last_sync_attempt = ? WHERE uuid = ?',
        [DateTime.now().toIso8601String(), uuid],
      );
    } catch (e) {
      SafeLogger.error('Error al incrementar intentos de sincronización', e);
    }
  }

  /// Guarda datos de referencia para uso offline
  Future<void> saveReferenceData(
      String tipo, Map<String, dynamic> datos) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.insert(
        'datos_referencia',
        {
          'tipo': tipo,
          'datos': jsonEncode(datos),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      SafeLogger.debug('Datos de referencia guardados: $tipo');
    } catch (e) {
      SafeLogger.error('Error al guardar datos de referencia', e);
    }
  }

  /// Obtiene datos de referencia guardados
  Future<Map<String, dynamic>?> getReferenceData(String tipo) async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: [tipo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return jsonDecode(result.first['datos'] as String);
      }
      return null;
    } catch (e) {
      SafeLogger.error('Error al obtener datos de referencia', e);
      return null;
    }
  }

  /// Genera un UUID simple para identificar registros offline
  String _generateUUID() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = (now.microsecond * 1000 + now.millisecond).toString();
    return 'offline_$timestamp$random';
  }

  /// Limpia registros antiguos sincronizados
  Future<void> cleanOldSyncedRecords({int daysToKeep = 7}) async {
    try {
      final db = await database;
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

      final deletedCount = await db.delete(
        'recargas_offline',
        where: 'synced = 1 AND created_at < ?',
        whereArgs: [cutoffDate],
      );

      SafeLogger.info(
          'Limpiados $deletedCount registros antiguos sincronizados');
    } catch (e) {
      SafeLogger.error('Error al limpiar registros antiguos', e);
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Guarda máquinas en caché
  Future<void> cacheMaquinas(List<Map<String, dynamic>> maquinas) async {
    try {
      final db = await database;

      // Limpiar cache anterior
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['maquinas']);

      // Guardar nuevos datos
      for (final maquina in maquinas) {
        await db.insert('datos_referencia', {
          'tipo': 'maquinas',
          'datos': jsonEncode(maquina),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      SafeLogger.info(
          'Cache de máquinas actualizado: ${maquinas.length} registros');
    } catch (e) {
      SafeLogger.error('Error al cachear máquinas', e);
    }
  }

  /// Obtiene máquinas desde caché
  Future<List<Map<String, dynamic>>> getCachedMaquinas() async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['maquinas'],
      );

      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener máquinas cacheadas', e);
      return [];
    }
  }

  /// Guarda obras en caché
  Future<void> cacheObras(List<Map<String, dynamic>> obras) async {
    try {
      final db = await database;
      await db
          .delete('datos_referencia', where: 'tipo = ?', whereArgs: ['obras']);

      for (final obra in obras) {
        await db.insert('datos_referencia', {
          'tipo': 'obras',
          'datos': jsonEncode(obra),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      SafeLogger.info('Cache de obras actualizado: ${obras.length} registros');
    } catch (e) {
      SafeLogger.error('Error al cachear obras', e);
    }
  }

  /// Obtiene obras desde caché
  Future<List<Map<String, dynamic>>> getCachedObras() async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['obras'],
      );

      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener obras cacheadas', e);
      return [];
    }
  }

  /// Guarda clientes en caché
  Future<void> cacheClientes(List<Map<String, dynamic>> clientes) async {
    try {
      final db = await database;
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['clientes']);

      for (final cliente in clientes) {
        await db.insert('datos_referencia', {
          'tipo': 'clientes',
          'datos': jsonEncode(cliente),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      SafeLogger.info(
          'Cache de clientes actualizado: ${clientes.length} registros');
    } catch (e) {
      SafeLogger.error('Error al cachear clientes', e);
    }
  }

  /// Obtiene clientes desde caché
  Future<List<Map<String, dynamic>>> getCachedClientes() async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['clientes'],
      );

      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener clientes cacheados', e);
      return [];
    }
  }

  /// Guarda operadores de una máquina en caché
  Future<void> cacheOperadoresMaquina(
      int maquinaId, List<Map<String, dynamic>> operadores) async {
    try {
      final db = await database;
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['operadores_$maquinaId']);

      for (final operador in operadores) {
        await db.insert('datos_referencia', {
          'tipo': 'operadores_$maquinaId',
          'datos': jsonEncode(operador),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      SafeLogger.info(
          'Cache de operadores para máquina $maquinaId: ${operadores.length}');
    } catch (e) {
      SafeLogger.error('Error al cachear operadores', e);
    }
  }

  /// Obtiene operadores de una máquina desde caché
  Future<List<Map<String, dynamic>>> getCachedOperadoresMaquina(
      int maquinaId) async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['operadores_$maquinaId'],
      );

      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener operadores cacheados', e);
      return [];
    }
  }

  /// Verifica si el caché está actualizado (menos de 24 horas)
  Future<bool> isCacheValid(String tipo) async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: [tipo],
        limit: 1,
      );

      if (result.isEmpty) return false;

      final updatedAt = DateTime.parse(result.first['updated_at'] as String);
      final now = DateTime.now();
      final difference = now.difference(updatedAt);

      return difference.inHours < 24; // Cache válido por 24 horas
    } catch (e) {
      return false;
    }
  }

  Future<void> cacheContratos(List<Map<String, dynamic>> contratos) async {
    try {
      final db = await database;
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['contratos']);

      for (final contrato in contratos) {
        await db.insert('datos_referencia', {
          'tipo': 'contratos',
          'datos': jsonEncode(contrato),
          'update_at': DateTime.now().toIso8601String(),
        });
      }
      SafeLogger.info(
          'Cache de contratos actualizados: ${contratos.length} registros');
    } catch (e) {
      SafeLogger.error('Error al cachear contratos', e);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedContratos() async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['contratos'],
      );
      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener contratos cacheados', e);
      return [];
    }
  }

  Future<void> cacheContratosMaquina(
      int maquinaId, List<Map<String, dynamic>> contratos) async {
    try {
      final db = await database;
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['contratos_maquina_$maquinaId']);

      for (final contrato in contratos) {
        await db.insert('datos_referencia', {
          'tipo': 'contratos_maquina_$maquinaId',
          'datos': jsonEncode(contrato),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      SafeLogger.info(
          'Cache de contratos por máquina $maquinaId: ${contratos.length}');
    } catch (e) {
      SafeLogger.error('Error al cachear contratos de máquina', e);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedContratosMaquina(
      int maquinaId) async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['contratos_maquina_$maquinaId'],
      );
      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener contratos cacheados de máquina', e);
      return [];
    }
  }

  /// Guarda reportes de contratos en caché
  Future<void> cacheContratosReportes(
      List<Map<String, dynamic>> reportes) async {
    try {
      final db = await database;
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['contratos_reportes']);

      for (final reporte in reportes) {
        await db.insert('datos_referencia', {
          'tipo': 'contratos_reportes',
          'datos': jsonEncode(reporte),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      SafeLogger.info(
          'Cache de reportes actualizado: ${reportes.length} registros');
    } catch (e) {
      SafeLogger.error('Error al cachear reportes', e);
    }
  }

  /// Obtiene reportes desde caché
  Future<List<Map<String, dynamic>>> getCachedContratosReportes() async {
    try {
      final db = await database;
      final result = await db.query(
        'datos_referencia',
        where: 'tipo = ?',
        whereArgs: ['contratos_reportes'],
      );

      return result.map((row) {
        return jsonDecode(row['datos'] as String) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener reportes cacheados', e);
      return [];
    }
  }

  /// 🆕 Guarda un reporte de contrato offline
  Future<String> saveReporteOffline({
    required String idReporte,
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
      final db = await database;
      final uuid = _generateReporteId();
      final now = DateTime.now().toIso8601String();

      await db.insert('reportes_offline', {
        'uuid': uuid,
        'id_reporte': idReporte,
        'fecha_reporte': fechaReporte,
        'pk_maquina': pkMaquina,
        'maquina_txt': maquinaTxt,
        'pk_contrato': pkContrato,
        'contrato_txt': contratoTxt,
        'odometro_inicial': odometroInicial,
        'odometro_final': odometroFinal,
        'horas_trabajadas': horasTrabajadas,
        'horas_minimas': horasMinimas,
        'km_inicial': kmInicial,
        'km_final': kmFinal,
        'kilometros': kilometros,
        'trabajo_realizado': trabajoRealizado,
        'estado_reporte': estadoReporte,
        'observaciones': observaciones,
        'incidente': incidente,
        'foto1': foto1,
        'foto2': foto2,
        'usuario_id': usuarioId,
        'usuario_nombre': usuarioNombre,
        'created_at': now,
      });

      SafeLogger.info('Reporte guardado offline con UUID: $uuid');
      return uuid;
    } catch (e) {
      SafeLogger.error('Error al guardar reporte offline', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingReportes() async {
    try {
      final db = await database;
      final result = await db.query(
        'reportes_offline',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener reportes pendientes', e);
      return [];
    }
  }

  Future<void> markReporteAsSynced(String uuid) async {
    try {
      final db = await database;
      await db.update(
        'reportes_offline',
        {
          'synced': 1,
          'last_sync_attempt': DateTime.now().toIso8601String(),
        },
        where: 'uuid = ?',
        whereArgs: [uuid],
      );
      SafeLogger.info('Reporte marcado como sincronico: $uuid');
    } catch (e) {
      SafeLogger.error('Error al marcar reporte como sincronizado', e);
    }
  }

  Future<void> incrementReporteSyncAttempts(String uuid) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE reportes_offline SET sync_attempts = sync_attempts + 1, last_sync_attempts = ? WHERE uuid = ?',
        [DateTime.now().toIso8601String(), uuid],
      );
    } catch (e) {
      SafeLogger.error('Error al incrementar intento de reporte', e);
    }
  }
}
