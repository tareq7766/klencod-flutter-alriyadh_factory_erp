import 'dart:convert';

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class ProductDatabase {
  ProductDatabase._();

  static final ProductDatabase instance = ProductDatabase._();

  static const String _databaseName = 'alriyadh_factory.db';
  static const String _tableName = 'products';
  static const String _migrationKey = 'products_migrated_to_sqlite_v1';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final fullPath = join(databasePath, _databaseName);

    _database = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            size TEXT NOT NULL DEFAULT '',
            price REAL NOT NULL DEFAULT 0,
            stock INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    return _database!;
  }

  /// يهيئ قاعدة البيانات وينقل المنتجات القديمة من SharedPreferences
  /// في أول تشغيل بعد إضافة SQLite.
  Future<void> initialize(SharedPreferences prefs) async {
    final db = await database;
    final alreadyMigrated = prefs.getBool(_migrationKey) ?? false;

    if (alreadyMigrated) {
      return;
    }

    final oldProductsJson = prefs.getString('factory_products');

    if (oldProductsJson != null && oldProductsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(oldProductsJson);

        if (decoded is List) {
          final batch = db.batch();

          for (final item in decoded) {
            if (item is! Map) {
              continue;
            }

            final product = Map<String, dynamic>.from(item);
            final id = product['id']?.toString();

            if (id == null || id.isEmpty) {
              continue;
            }

            batch.insert(
              _tableName,
              {
                'id': id,
                'name': product['name']?.toString() ?? '',
                'size': product['size']?.toString() ?? '',
                'price': product['price'] is num
                    ? (product['price'] as num).toDouble()
                    : 0.0,
                'stock': product['stock'] is num
                    ? (product['stock'] as num).toInt()
                    : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await batch.commit();
        }
      } catch (_) {
        // لا يوقف تعذّر قراءة البيانات القديمة تشغيل التطبيق.
      }
    }

    await prefs.setBool(_migrationKey, true);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;

    return db.query(
      _tableName,
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<void> saveProduct(Map<String, dynamic> product) async {
    final db = await database;

    await db.insert(
      _tableName,
      {
        'id': product['id'].toString(),
        'name': product['name']?.toString() ?? '',
        'size': product['size']?.toString() ?? '',
        'price': (product['price'] as num?)?.toDouble() ?? 0.0,
        'stock': (product['stock'] as num?)?.toInt() ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}