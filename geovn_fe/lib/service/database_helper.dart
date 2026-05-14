import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vietnam_provinces.db');

    if (!await databaseExists(path)) {
      try {
        final data = await rootBundle.load('assets/vietnam_provinces.db');
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await databaseFactory.writeDatabaseBytes(path, bytes);
      } catch (e, st) {
        debugPrint('Error seeding database from assets: $e\n$st');
      }
    }

    final db = await openDatabase(path);
    await _ensureProvinceColumns(db);
    return db;
  }

  /// Asset DB historically only had `geometry`. App code expects optional merger columns.
  static Future<void> _ensureProvinceColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(provinces)');
    final cols = rows.map((r) => r['name'] as String).toSet();
    if (!cols.contains('old_geometry')) {
      await db.execute('ALTER TABLE provinces ADD COLUMN old_geometry TEXT');
    }
    if (!cols.contains('is_merged')) {
      await db.execute('ALTER TABLE provinces ADD COLUMN is_merged INTEGER DEFAULT 0');
    }
    if (!cols.contains('merged_into_id')) {
      await db.execute('ALTER TABLE provinces ADD COLUMN merged_into_id TEXT');
    }
  }

  static Future<List<Map<String, dynamic>>> getProvinces() async {
    final db = await database;
    return db.query('provinces');
  }
}
