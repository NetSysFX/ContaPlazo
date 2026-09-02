import 'package:sqflite/sqflite.dart';

abstract interface class ClientStore {
  Future<List<Map<String, Object?>>> loadClients();
  Future<void> saveClients(List<Map<String, Object?>> clients);
  Future<Map<String, Object?>?> loadAccountant();
  Future<void> saveAccountant(Map<String, Object?> accountant);
}

class LocalDatabase implements ClientStore {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await openDatabase(
    'contaplazo.db',
    version: 2,
    onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE clients (
        nit TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        due_date TEXT NOT NULL,
        fee REAL NOT NULL,
        paid INTEGER NOT NULL,
        document_count INTEGER NOT NULL,
        tax_status INTEGER NOT NULL
      )
      ''');
      await _createAccountantTable(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) await _createAccountantTable(db);
    },
  );

  static Future<void> _createAccountantTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS accountant (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      name TEXT NOT NULL,
      professional_id TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT NOT NULL,
      firm TEXT NOT NULL
    )
  ''');

  @override
  Future<List<Map<String, Object?>>> loadClients() async {
    final db = await database;
    return db.query('clients', orderBy: 'due_date ASC');
  }

  @override
  Future<void> saveClients(List<Map<String, Object?>> clients) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete('clients');
      final batch = transaction.batch();
      for (final client in clients) {
        batch.insert(
          'clients',
          client,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<Map<String, Object?>?> loadAccountant() async {
    final db = await database;
    final rows = await db.query('accountant', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> saveAccountant(Map<String, Object?> accountant) async {
    final db = await database;
    await db.insert('accountant', {
      'id': 1,
      ...accountant,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
