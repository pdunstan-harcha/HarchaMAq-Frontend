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
        version: 1,
        onCreate: _createTables,
      );
    } catch (e) {
      SafeLogger.error('Error al inicializar base de datos offline', e);
      rethrow;
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
      final uuid = _generateUUID();
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
}
