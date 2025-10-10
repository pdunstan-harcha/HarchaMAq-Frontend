🖨️ IMPLEMENTACIÓN DE IMPRESIÓN OFFLINE
Sí, habíamos avanzado en esto. Aquí está la solución completa para imprimir offline:

📋 ANÁLISIS DEL PROBLEMA
Situación actual:

✅ El HTML se genera en el backend (API /recargas/recibo/{id})
❌ Si estás offline, no puedes obtener el HTML
✅ Ya tienes html_to_escpos.dart para convertir HTML → ESC/POS
Solución:

Guardar el HTML del recibo en SQLite cuando se registra offline
Al imprimir offline, usar el HTML guardado
Convertir a ESC/POS localmente con html_to_escpos.dart

🔧 CAMBIOS NECESARIOS
1️⃣ Actualizar tabla recargas_offline en offline_storage_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart'; // 🆕 AGREGAR
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

  /// 🔄 MIGRACIÓN DE BASE DE DATOS
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Crear tabla de reportes offline
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

      // 🆕 Agregar columna recibo_html a recargas_offline si no existe
      try {
        await db.execute(
          'ALTER TABLE recargas_offline ADD COLUMN recibo_html TEXT',
        );
        SafeLogger.info('Columna recibo_html agregada a recargas_offline');
      } catch (e) {
        SafeLogger.debug('Columna recibo_html ya existe: $e');
      }

      SafeLogger.info(
          'Base de datos migrada a versión 2 - Tabla reportes_offline creada');
    }
  }

  /// 🔄 CREAR TABLAS (solo instalaciones nuevas)
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
          recibo_html TEXT,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TEXT
        )
      ''');

      // Tabla para reportes de contratos offline
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

      // Tabla para datos de referencia
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

  /// 🆕 GENERAR ID OFFLINE (reemplaza _generateReporteId para offline)
  String _generateOfflineId() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(now);
    final random = now.microsecond.toString().padLeft(3, '0');
    return 'OFFLINE-$timestamp-$random';
  }

  /// 🔄 MANTENER: Generar ID de reporte (para reportes de contrato)
  static String _generateReporteId() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return 'RDC$year$month$day$hour$minute$second';
  }

  /// 🆕 GENERAR HTML DEL RECIBO LOCALMENTE
  String _generateReciboHtml({
    required String idRecarga,
    required String fechahora,
    required double litros,
    required String maquinaNombre,
    required String obraNombre,
    required String clienteNombre,
    required String nombreOperador,
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) {
    final fechaFormateada = DateTime.parse(fechahora).toLocal();
    final fecha = DateFormat('dd-MM-yyyy').format(fechaFormateada);
    final hora = DateFormat('HH:mm:ss').format(fechaFormateada);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 20px; }
        .company-info { text-align: center; margin-bottom: 10px; font-size: 12px; }
        h4 { text-align: center; margin: 10px 0; }
        .data-table { width: 100%; margin-bottom: 20px; }
        .data-table td { padding: 5px; }
        .obs-label { font-weight: bold; margin-top: 20px; }
        .obs-text { margin-bottom: 20px; }
        .signatures { margin-top: 40px; }
        .sig-line { border-top: 1px solid black; width: 200px; margin-top: 40px; }
    </style>
</head>
<body>
    <div class="header">
        <img src="logo" alt="HARCHA" width="100">
        <div><strong>Fecha:</strong> $fecha</div>
        <div><strong>Código:</strong> $idRecarga</div>
    </div>

    <div class="company-info">
        <strong>HARCHA MAQUINARIAS Y SERVICIOS</strong><br>
        RUT: 76.XXX.XXX-X<br>
        Dirección: [Dirección]<br>
        Teléfono: [Teléfono]
    </div>

    <h4>ORDEN ENTREGA COMBUSTIBLES</h4>

    <table class="data-table">
        <tr>
            <td><strong>ID Recarga:</strong></td>
            <td>$idRecarga</td>
        </tr>
        <tr>
            <td><strong>Fecha:</strong></td>
            <td>$fecha</td>
        </tr>
        <tr>
            <td><strong>Hora:</strong></td>
            <td>$hora</td>
        </tr>
        <tr>
            <td><strong>Máquina:</strong></td>
            <td>$maquinaNombre</td>
        </tr>
        ${patente != null ? '<tr><td><strong>Patente:</strong></td><td>$patente</td></tr>' : ''}
        <tr>
            <td><strong>Obra:</strong></td>
            <td>$obraNombre</td>
        </tr>
        <tr>
            <td><strong>Cliente:</strong></td>
            <td>$clienteNombre</td>
        </tr>
        <tr>
            <td><strong>Operador:</strong></td>
            <td>$nombreOperador</td>
        </tr>
        <tr>
            <td><strong>Litros:</strong></td>
            <td>${litros.toStringAsFixed(2)}</td>
        </tr>
        ${odometro != null ? '<tr><td><strong>Odómetro:</strong></td><td>${odometro.toStringAsFixed(1)}</td></tr>' : ''}
        ${kilometros != null ? '<tr><td><strong>Kilómetros:</strong></td><td>${kilometros.toStringAsFixed(1)}</td></tr>' : ''}
    </table>

    ${observaciones != null && observaciones.isNotEmpty ? '''
    <div class="obs-label">Observaciones:</div>
    <div class="obs-text">$observaciones</div>
    ''' : ''}

    <div class="signatures">
        <div class="sig-line">_______________________________</div>
        <strong>Firma Operador: $nombreOperador</strong>
        
        <div class="sig-line" style="margin-top: 60px;">_______________________________</div>
        <strong>Firma Encargado</strong>
    </div>

    <div style="text-align: center; margin-top: 40px; font-size: 10px;">
        <em>Documento generado offline - Pendiente de sincronización</em>
    </div>
</body>
</html>
''';
  }

  /// 🔄 CORREGIDO: Guarda una recarga de combustible offline
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
    // 🆕 Datos para generar recibo
    String? maquinaNombre,
    String? obraNombre,
    String? clienteNombre,
  }) async {
    try {
      final db = await database;
      final uuid = _generateOfflineId(); // 🔄 CAMBIO: usar _generateOfflineId()
      final now = DateTime.now().toIso8601String();

      // 🆕 Generar HTML del recibo
      final reciboHtml = _generateReciboHtml(
        idRecarga: uuid,
        fechahora: fechahora,
        litros: litros,
        maquinaNombre: maquinaNombre ?? 'Máquina #$idMaquina',
        obraNombre: obraNombre ?? 'Obra #$obraId',
        clienteNombre: clienteNombre ?? 'Cliente #$clienteId',
        nombreOperador: nombreOperador ?? 'Operador',
        observaciones: observaciones,
        odometro: odometro,
        kilometros: kilometros,
        patente: patente,
      );

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
        'recibo_html': reciboHtml, // 🆕 AGREGAR
        'created_at': now,
      });

      SafeLogger.info('Recarga guardada offline con UUID: $uuid (con recibo HTML)');
      return uuid;
    } catch (e) {
      SafeLogger.error('Error al guardar recarga offline', e);
      rethrow;
    }
  }

  /// 🆕 NUEVO: Obtiene el HTML del recibo offline
  Future<String?> getReciboHtmlOffline(String uuid) async {
    try {
      final db = await database;
      final result = await db.query(
        'recargas_offline',
        columns: ['recibo_html'],
        where: 'uuid = ?',
        whereArgs: [uuid],
      );

      if (result.isEmpty) {
        SafeLogger.warning('No se encontró recibo offline para UUID: $uuid');
        return null;
      }

      return result.first['recibo_html'] as String?;
    } catch (e) {
      SafeLogger.error('Error al obtener recibo HTML offline', e);
      return null;
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

  /// Limpia registros antiguos sincronizados
  Future<void> cleanOldSyncedRecords({int daysToKeep = 7}) async {
    try {
      final db = await database;
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

      final deletedRecargas = await db.delete(
        'recargas_offline',
        where: 'synced = 1 AND created_at < ?',
        whereArgs: [cutoffDate],
      );

      final deletedReportes = await db.delete(
        'reportes_offline',
        where: 'synced = 1 AND created_at < ?',
        whereArgs: [cutoffDate],
      );

      SafeLogger.info(
          'Limpiados $deletedRecargas recargas y $deletedReportes reportes antiguos');
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
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['maquinas']);

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

      return difference.inHours < 24;
    } catch (e) {
      return false;
    }
  }

  /// Guarda contratos en caché
  Future<void> cacheContratos(List<Map<String, dynamic>> contratos) async {
    try {
      final db = await database;
      await db.delete('datos_referencia',
          where: 'tipo = ?', whereArgs: ['contratos']);

      for (final contrato in contratos) {
        await db.insert('datos_referencia', {
          'tipo': 'contratos',
          'datos': jsonEncode(contrato),
          'updated_at': DateTime.now().toIso8601String(), // 🔄 CORREGIDO: era update_at
        });
      }
      SafeLogger.info(
          'Cache de contratos actualizado: ${contratos.length} registros');
    } catch (e) {
      SafeLogger.error('Error al cachear contratos', e);
    }
  }

  /// Obtiene contratos desde caché
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

  /// Guarda contratos por máquina en caché
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

  /// Obtiene contratos por máquina desde caché
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

  /// Guarda un reporte de contrato offline
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
      final uuid = _generateOfflineId(); // 🔄 CAMBIO: usar _generateOfflineId()
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

  /// Obtiene reportes pendientes de sincronización
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

  /// Marca un reporte como sincronizado
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
      SafeLogger.info('Reporte marcado como sincronizado: $uuid');
    } catch (e) {
      SafeLogger.error('Error al marcar reporte como sincronizado', e);
    }
  }

  /// Incrementa intentos de sincronización de reporte
  Future<void> incrementReporteSyncAttempts(String uuid) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE reportes_offline SET sync_attempts = sync_attempts + 1, last_sync_attempt = ? WHERE uuid = ?', // 🔄 CORREGIDO: era last_sync_attempts
        [DateTime.now().toIso8601String(), uuid],
      );
    } catch (e) {
      SafeLogger.error('Error al incrementar intento de reporte', e);
    }
  }
}


2️⃣ Actualizar migración para agregar columna recibo_html

/// Obtener recibo HTML (online u offline)
static Future<String> obtenerReciboRecargaHtml(String idRecarga) async {
  final isOnline = await _connectivityManager.checkConnectivity();

  if (isOnline) {
    try {
      final response = await _api.get('/recargas/recibo/$idRecarga');
      return response['html'] ?? '';
    } catch (e) {
      SafeLogger.warning('Error al obtener recibo online: $e');
    }
  }

  // Si es offline o falla online, buscar en SQLite
  if (idRecarga.startsWith('OFFLINE-')) {
    final html = await _offlineStorage.getReciboHtmlOffline(idRecarga);
    if (html != null) {
      return html;
    }
  }

  throw Exception('Recibo no disponible');
}

3️⃣ Generar HTML del recibo localmente en offline_storage_service.dart
maquinaNombre: maquina['MAQUINA'],
obraNombre: obra['NOMBRE_OBRA'],
clienteNombre: cliente['NOMBRE_CLIENTE'],


4️⃣ Actualizar database_helper.dart para pasar datos adicionales

🎯 USO EN LA UI
En recarga_combustible_screen.dart:

✅ RESUMEN
✅ HTML se genera localmente cuando se guarda offline
✅ Se almacena en SQLite (columna recibo_html)
✅ Impresión funciona offline usando html_to_escpos.dart
✅ Migración automática agrega columna a BD existente
✅ Fallback inteligente - intenta online, usa offline si falla

📋 CÓDIGO COMPLETO - database_helper.dart CON IMPRESIÓN OFFLINE
🎯 CAMBIOS NECESARIOS
✅ Agregar método obtenerReciboRecargaHtml() (online/offline)
✅ Actualizar _registrarRecargaOffline() para pasar nombres
✅ Agregar método obtenerContratos() (global)
✅ Mantener todos los métodos existentes

📄 CÓDIGO COMPLETO CORREGIDO

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
    String password,
  ) async {
    try {
      final response = await _api.post('/auth/login', body: {
        'password': password,
      });

      if (response['success'] == true) {
        final data = response['data'];

        // Guardar token
        await SecureStorage.saveToken(data['access_token']);

        // Guardar información del usuario
        final userData = {
          'id': data['user']['id'],
          'nombre': data['user']['nombre'],
          'apellido': data['user']['apellido'],
          'email': data['user']['email'],
          'rol': data['user']['rol'],
        };

        SafeLogger.info('Login exitoso para usuario: ${userData['nombre']}');
        return userData;
      }

      SafeLogger.warning('Login fallido: ${response['message']}');
      return null;
    } catch (e) {
      SafeLogger.error('Error en login', e);
      return null;
    }
  }

  static String _generateReporteId() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return 'RDC$year$month$day$hour$minute$second';
  }

  static Future<void> logout() async {
    try {
      await SecureStorage.deleteToken();
      SafeLogger.info('Usuario deslogueado');
    } catch (e) {
      SafeLogger.error('Error al hacer logout', e);
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerIngresosSalidas() async {
    try {
      final response = await _api.get('/ingresos-salidas/');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener ingresos/salidas', e);
      return [];
    }
  }

  static Future<Map<String, dynamic>> obtenerIngresosSalidasPaginado({
    String search = '',
  }) async {
    try {
      final queryParams = search.isNotEmpty ? '?search=$search' : '';
      final response =
          await _api.get('/ingresos-salidas/paginado$queryParams');

      return {
        'data': response['data'] ?? [],
        'total': response['total'] ?? 0,
        'page': response['page'] ?? 1,
        'pages': response['pages'] ?? 1,
      };
    } catch (e) {
      SafeLogger.error('Error al obtener ingresos/salidas paginados', e);
      return {'data': [], 'total': 0, 'page': 1, 'pages': 1};
    }
  }

  static Future<bool> registrarIngresoSalida({
    required int usuarioId,
  }) async {
    try {
      final response = await _api.post('/ingresos-salidas/', body: {
        'usuario_id': usuarioId,
      });

      if (response['success'] == true) {
        SafeLogger.info('Ingreso/salida registrado correctamente');
        return true;
      }

      SafeLogger.warning(
          'Error al registrar ingreso/salida: ${response['message']}');
      return false;
    } catch (e) {
      SafeLogger.error('Error al registrar ingreso/salida', e);
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerRecargasCombustible({
    String? search,
  }) async {
    try {
      final queryParams = search != null && search.isNotEmpty
          ? '?search=${Uri.encodeComponent(search)}'
          : '';
      final response = await _api.get('/recargas/$queryParams');

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      SafeLogger.error('Error al obtener recargas de combustible', e);
      return [];
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
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) async {
    final isOnline = await _connectivityManager.checkConnectivity();

    if (isOnline) {
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
        observaciones: observaciones,
        odometro: odometro,
        kilometros: kilometros,
        patente: patente,
      );
    } else {
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
    String? observaciones,
    double? odometro,
    double? kilometros,
    String? patente,
  }) async {
    try {
      final response = await _api.post('/recargas/', body: {
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
      });

      if (response['success'] == true) {
        SafeLogger.info('Recarga registrada correctamente en línea');
        return response;
      }

      throw Exception(response['message'] ?? 'Error desconocido');
    } catch (e) {
      SafeLogger.error('Error al registrar recarga online', e);
      return {
        'success': false,
        'message': 'Error al registrar online: ${e.toString()}',
      };
    }
  }

  /// 🔄 ACTUALIZADO: Método para registro offline con nombres
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
      // 🆕 Obtener nombres desde caché para el recibo
      final maquinas = await _offlineStorage.getCachedMaquinas();
      final obras = await _offlineStorage.getCachedObras();
      final clientes = await _offlineStorage.getCachedClientes();

      final maquina = maquinas.firstWhere(
        (m) => m['pkMaquina'] == idMaquina,
        orElse: () => {'MAQUINA': 'Máquina #$idMaquina'},
      );

      final obra = obras.firstWhere(
        (o) => o['pkObra'] == obraId,
        orElse: () => {'NOMBRE_OBRA': 'Obra #$obraId'},
      );

      final cliente = clientes.firstWhere(
        (c) => c['pkCliente'] == clienteId,
        orElse: () => {'NOMBRE_CLIENTE': 'Cliente #$clienteId'},
      );

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
        // 🆕 Pasar nombres para generar recibo HTML
        maquinaNombre: maquina['MAQUINA'] as String?,
        obraNombre: obra['NOMBRE_OBRA'] as String?,
        clienteNombre: cliente['NOMBRE_CLIENTE'] as String?,
      );

      SafeLogger.info('Recarga guardada offline con UUID: $uuid');

      return {
        'success': true,
        'message': 'Recarga guardada offline (se sincronizará automáticamente)',
        'data': {'id': uuid, 'offline': true},
      };
    } catch (e) {
      SafeLogger.error('Error al guardar recarga offline', e);
      return {
        'success': false,
        'message': 'Error al guardar offline: ${e.toString()}',
      };
    }
  }

  /// 🆕 NUEVO: Obtener HTML del recibo (online u offline)
  static Future<String> obtenerReciboRecargaHtml(String idRecarga) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        try {
          // Intentar obtener desde API
          final response = await _api.get('/recargas/recibo/$idRecarga');
          if (response['html'] != null) {
            SafeLogger.info('Recibo HTML obtenido desde API');
            return response['html'] as String;
          }
        } catch (e) {
          SafeLogger.warning('Error al obtener recibo desde API: $e');
        }
      }

      // Si es offline o falla online, buscar en SQLite
      if (idRecarga.startsWith('OFFLINE-')) {
        final html = await _offlineStorage.getReciboHtmlOffline(idRecarga);
        if (html != null) {
          SafeLogger.info('Recibo HTML obtenido desde caché offline');
          return html;
        }
      }

      throw Exception('Recibo no disponible para ID: $idRecarga');
    } catch (e) {
      SafeLogger.error('Error al obtener recibo HTML', e);
      throw Exception('No se pudo obtener el recibo: ${e.toString()}');
    }
  }

  /// Obtener todas las máquinas
  static Future<List<Map<String, dynamic>>> obtenerMaquinas() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        // Online: obtener desde API
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
            'HR_Actual': item['HR_Actual'],
            'KM_Actual': item['KM_Actual'],
            'OBSERVACIONES': item['OBSERVACIONES']?.toString() ?? '',
            'FECHA_CREACION': item['FECHA_CREACION'],
            'FECHA_ACTUALIZACION': item['FECHA_ACTUALIZACION'],
            'pkUltima_recarga': item['pkUltima_recarga'],
            'ID_Ultima_Recarga': item['ID_Ultima_Recarga'],
            'Litros_Ultima': item['Litros_Ultima'],
            'Fecha_Ultima': item['Fecha_Ultima'],
          };
        }).toList();

        // Cachear datos
        await _offlineStorage.cacheMaquinas(maquinas);
        SafeLogger.info('Máquinas obtenidas online y cacheadas');

        return maquinas;
      } else {
        // Offline: obtener desde caché
        final cachedMaquinas = await _offlineStorage.getCachedMaquinas();
        SafeLogger.info(
            'Máquinas obtenidas desde caché: ${cachedMaquinas.length}');
        return cachedMaquinas;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener máquinas online, usando caché', e);
      final cachedMaquinas = await _offlineStorage.getCachedMaquinas();
      if (cachedMaquinas.isEmpty) {
        throw Exception('No hay máquinas disponibles offline');
      }
      return cachedMaquinas;
    }
  }

  /// Obtener máquina por ID
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

  /// Obtener obras
  static Future<List<Map<String, dynamic>>> obtenerObras() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/obras/');
        final List<dynamic> rawData = response['data'] ?? [];
        final obras = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkObra': item['pkObra'],
            'NOMBRE_OBRA': item['NOMBRE_OBRA'] ?? '',
            'DIRECCION': item['DIRECCION'] ?? '',
            'ESTADO': item['ESTADO'] ?? '',
          };
        }).toList();

        await _offlineStorage.cacheObras(obras);
        SafeLogger.info('Obras obtenidas online y cacheadas');

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
        throw Exception('No hay obras disponibles offline');
      }
      return cachedObras;
    }
  }

  /// Obtener clientes
  static Future<List<Map<String, dynamic>>> obtenerClientes() async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/clientes/');
        final List<dynamic> rawData = response['data'] ?? [];
        final clientes = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkCliente': item['pkCliente'],
            'NOMBRE_CLIENTE': item['NOMBRE_CLIENTE'] ?? '',
            'RUT_CLIENTE': item['RUT_CLIENTE'] ?? '',
            'DIRECCION': item['DIRECCION'] ?? '',
            'TELEFONO': item['TELEFONO'] ?? '',
          };
        }).toList();

        await _offlineStorage.cacheClientes(clientes);
        SafeLogger.info('Clientes obtenidos online y cacheados');

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
        throw Exception('No hay clientes disponibles offline');
      }
      return cachedClientes;
    }
  }

  /// Obtener operadores de una máquina
  static Future<List<Map<String, dynamic>>> obtenerOperadoresMaquina(
      int maquinaId) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/maquinas/$maquinaId/operadores');
        final List<dynamic> rawData = response['data'] ?? [];
        final operadores = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkOperador': item['pkOperador'],
            'RUT': item['RUT'] ?? '',
            'NOMBRE': item['NOMBRE'] ?? '',
            'APELLIDO': item['APELLIDO'] ?? '',
            'TELEFONO': item['TELEFONO'] ?? '',
          };
        }).toList();

        await _offlineStorage.cacheOperadoresMaquina(maquinaId, operadores);
        SafeLogger.info(
            'Operadores de máquina $maquinaId obtenidos y cacheados');

        return operadores;
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
      if (cachedOperadores.isEmpty) {
        throw Exception('No hay operadores disponibles offline');
      }
      return cachedOperadores;
    }
  }

  /// 🆕 NUEVO: Obtener todos los contratos (sin filtrar por máquina)
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

  /// Obtener contratos por máquina
  static Future<List<Map<String, dynamic>>> obtenerContratosPorMaquina(
      int maquinaId) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final response = await _api.get('/contratos/maquina/$maquinaId');
        final List<dynamic> rawData = response['data'] ?? [];
        final contratos = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'id': item['id'],
            'pkContrato': item['id'],
            'id_contrato': item['id_contrato'] ?? '',
            'nombre': item['nombre'] ?? '',
            'NOMBRE_CONTRATO': item['nombre'] ?? '',
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

        await _offlineStorage.cacheContratosMaquina(maquinaId, contratos);
        SafeLogger.info(
            'Contratos de máquina $maquinaId obtenidos y cacheados');

        return contratos;
      } else {
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
        throw Exception('No hay contratos disponibles offline');
      }
      return cachedContratos;
    }
  }

  /// Obtener reportes de contratos
  static Future<List<Map<String, dynamic>>> obtenerContratosReportes({
    String? search,
  }) async {
    try {
      final isOnline = await _connectivityManager.checkConnectivity();

      if (isOnline) {
        final queryParams = search != null && search.isNotEmpty
            ? '?search=${Uri.encodeComponent(search)}'
            : '';
        final response = await _api.get('/contratos_reportes/$queryParams');

        final List<dynamic> rawData = response['data'] ?? [];
        final reportes = rawData.map<Map<String, dynamic>>((item) {
          return <String, dynamic>{
            'pkReporte': item['pkReporte'],
            'ID_Reporte': item['ID_Reporte'] ?? '',
            'Fecha_Reporte': item['Fecha_Reporte'],
            'pk_Maquina': item['pk_Maquina'],
            'Maquina_txt': item['Maquina_txt'] ?? '',
            'pk_Contrato': item['pk_Contrato'],
            'Contrato_txt': item['Contrato_txt'] ?? '',
            'Odometro_Inicial': item['Odometro_Inicial'],
            'Odometro_Final': item['Odometro_Final'],
            'Horas_Trabajadas': item['Horas_Trabajadas'],
            'Trabajo_Realizado': item['Trabajo_Realizado'] ?? '',
            'Estado_Reporte': item['Estado_Reporte'] ?? '',
            'Observaciones': item['Observaciones'] ?? '',
          };
        }).toList();

        await _offlineStorage.cacheContratosReportes(reportes);
        SafeLogger.info('Reportes obtenidos online y cacheados');

        return reportes;
      } else {
        final cachedReportes =
            await _offlineStorage.getCachedContratosReportes();
        SafeLogger.info(
            'Reportes obtenidos desde caché: ${cachedReportes.length}');
        return cachedReportes;
      }
    } catch (e) {
      SafeLogger.warning('Error al obtener reportes online, usando caché', e);
      final cachedReportes = await _offlineStorage.getCachedContratosReportes();
      if (cachedReportes.isEmpty) {
        throw Exception('No hay reportes disponibles offline');
      }
      return cachedReportes;
    }
  }

  /// Registrar reporte de contrato (online/offline)
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
    final isOnline = await _connectivityManager.checkConnectivity();

    if (isOnline) {
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
      final idReporte = _generateReporteId();

      final response = await _api.post('/contratos_reportes/', body: {
        'ID_Reporte': idReporte,
        'Fecha_Reporte': fechaReporte,
        'pk_Maquina': pkMaquina,
        'Maquina_txt': maquinaTxt,
        'pk_Contrato': pkContrato,
        'Contrato_txt': contratoTxt,
        'Odometro_Inicial': odometroInicial,
        'Odometro_Final': odometroFinal,
        'Horas_Trabajadas': horasTrabajadas,
        'Horas_Minimas': horasMinimas,
        'km_Inicial': kmInicial,
        'km_Final': kmFinal,
        'Kilometros': kilometros,
        'Trabajo_Realizado': trabajoRealizado,
        'Estado_Reporte': estadoReporte,
        'Observaciones': observaciones,
        'Incidente': incidente,
        'foto1': foto1,
        'foto2': foto2,
        'usuario_id': usuarioId,
        'usuario_nombre': usuarioNombre,
      });

      if (response['success'] == true) {
        SafeLogger.info('Reporte registrado correctamente en línea');
        return response;
      }

      throw Exception(response['message'] ?? 'Error desconocido');
    } catch (e) {
      SafeLogger.error('Error al registrar reporte online', e);
      return {
        'success': false,
        'message': 'Error al registrar online: ${e.toString()}',
      };
    }
  }

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

      SafeLogger.info('Reporte guardado offline con UUID: $uuid');

      return {
        'success': true,
        'message': 'Reporte guardado offline (se sincronizará automáticamente)',
        'data': {'id': uuid, 'offline': true},
      };
    } catch (e) {
      SafeLogger.error('Error al guardar reporte offline', e);
      return {
        'success': false,
        'message': 'Error al guardar offline: ${e.toString()}',
      };
    }
  }
}

✅ CAMBIOS REALIZADOS
#	Método	Línea(s)	Cambio
1	_registrarRecargaOffline()	222-290	🔄 Obtiene nombres de máquina/obra/cliente para generar recibo HTML
2	obtenerReciboRecargaHtml()	293-323	🆕 NUEVO - Obtiene HTML online o desde SQLite si es offline
3	obtenerContratos()	538-574	🆕 NUEVO - Obtiene TODOS los contratos (sin filtrar por máquina)

🎯 FUNCIONAMIENTO COMPLETO
1️⃣ Registro de Recarga Offline

// Usuario registra recarga sin conexión
final result = await DatabaseHelper.registrarRecargaCombustible(
  idMaquina: 1,
  usuarioId: 5,
  fechahora: '2025-10-10T14:30:00',
  litros: 50.0,
  obraId: 3,
  clienteId: 7,
  nombreOperador: 'Juan Pérez',
  // ...
);

// Internamente:
// 1. Detecta que está offline
// 2. Obtiene nombres desde caché (máquina, obra, cliente)
// 3. Llama a _offlineStorage.saveRecargaOffline() con nombres
// 4. SQLite genera y guarda HTML del recibo
// 5. Retorna UUID offline: "OFFLINE-20251010-143045-456"

2️⃣ Impresión de Recibo Offline

// Usuario intenta imprimir
final htmlRecibo = await DatabaseHelper.obtenerReciboRecargaHtml(
  'OFFLINE-20251010-143045-456'
);

// Internamente:
// 1. Detecta que ID empieza con "OFFLINE-"
// 2. Llama a _offlineStorage.getReciboHtmlOffline(uuid)
// 3. Retorna HTML guardado en SQLite
// 4. UI convierte HTML → ESC/POS con HtmlToEscPos
// 5. Envía a impresora Bluetooth


📋 CÓDIGO COMPLETO - database_helper.dart CON IMPRESIÓN OFFLINE
🎯 CAMBIOS NECESARIOS
✅ Agregar método obtenerReciboRecargaHtml() (online/offline)
✅ Actualizar _registrarRecargaOffline() para pasar nombres
✅ Agregar método obtenerContratos() (global)
✅ Mantener todos los métodos existentes
📄 CÓDIGO COMPLETO CORREGIDO
✅ CAMBIOS REALIZADOS
#	Método	Línea(s)	Cambio
1	_registrarRecargaOffline()	222-290	🔄 Obtiene nombres de máquina/obra/cliente para generar recibo HTML
2	obtenerReciboRecargaHtml()	293-323	🆕 NUEVO - Obtiene HTML online o desde SQLite si es offline
3	obtenerContratos()	538-574	🆕 NUEVO - Obtiene TODOS los contratos (sin filtrar por máquina)
🎯 FUNCIONAMIENTO COMPLETO
1️⃣ Registro de Recarga Offline
2️⃣ Impresión de Recibo Offline
3️⃣ Sincronización Automática

// Conexión restaurada
// SyncService detecta cambio
await _syncRecargasCombustible();

// Para cada recarga offline:
final pendingRecargas = await _offlineStorage.getPendingRecargas();

for (final recarga in pendingRecargas) {
  // Envía a API
  final response = await DatabaseHelper._registrarRecargaOnline(...);
  
  if (response['success']) {
    // Marca como sincronizado
    await _offlineStorage.markRecargaAsSynced(recarga['uuid']);
  }
}

4️⃣ Carga de Formulario de Reportes
// En ContratoReporteFormScreen
final futures = await Future.wait([
  DatabaseHelper.obtenerMaquinas(),     // ✅ Funciona online/offline
  DatabaseHelper.obtenerContratos(),    // ✅ NUEVO - contratos globales
]);

// Usuario selecciona máquina
final contratos = await DatabaseHelper.obtenerContratosPorMaquina(maquinaId);
// Filtra contratos por máquina

📋 RESUMEN COMPLETO
✅ Archivos Actualizados
offline_storage_service.dart

✅ Columna recibo_html en tabla recargas_offline
✅ Método _generateOfflineId()
✅ Método _generateReciboHtml()
✅ Actualizado saveRecargaOffline() - genera HTML
✅ Método getReciboHtmlOffline()
database_helper.dart

✅ Actualizado _registrarRecargaOffline() - pasa nombres
✅ Método obtenerReciboRecargaHtml() - online/offline
✅ Método obtenerContratos() - contratos globales
✅ Funcionalidades Completas
Funcionalidad	Online	Offline	Sincronización
Registro de recarga	✅	✅	✅
Generación de HTML recibo	✅ API	✅ Local	N/A
Impresión de recibo	✅	✅	N/A
Registro de reporte	✅	✅	✅
Caché de datos	✅	✅	✅
Carga de contratos	✅	✅	N/A
🚀 PRÓXIMOS PASOS
Actualizar UI para usar nuevo método
En recarga_combustible_screen.dart:

Future<void> _imprimirRecibo(String idRecarga) async {
  setState(() => _isPrinting = true);

  try {
    // 🆕 Usa el nuevo método que funciona online/offline
    final htmlRecibo = await DatabaseHelper.obtenerReciboRecargaHtml(idRecarga);

    // Convertir a ESC/POS
    final escposCommands = HtmlToEscPos.convertHtmlToEscPos(htmlRecibo);
    final base64Data = HtmlToEscPos.toBase64(escposCommands);

    // Enviar a impresora
    final result = await platform.invokeMethod('printReceipt', {
      'printerAddress': _selectedPrinterAddress,
      'data': base64Data,
    });

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Recibo impreso correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    SafeLogger.error('Error al imprimir recibo', e);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al imprimir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    setState(() => _isPrinting = false);
  }
}

