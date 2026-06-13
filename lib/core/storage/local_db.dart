import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

/// Local SQLite database for offline-capable data persistence.
/// Tables mirror the server schema (PRD §35) but store only what's needed locally.
class LocalDb {
  LocalDb._();
  static LocalDb? _instance;
  static LocalDb get instance => _instance ??= LocalDb._();

  Database? _db;
  Database get db {
    assert(_db != null, 'LocalDb.init() must be called first');
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    _db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_orders (
        id TEXT PRIMARY KEY,
        local_order_id TEXT NOT NULL UNIQUE,
        order_number TEXT,
        business_id TEXT,
        outlet_id TEXT,
        user_id TEXT,
        shift_id TEXT,
        device_id TEXT,
        customer_name TEXT,
        table_number TEXT,
        note TEXT,
        subtotal INTEGER NOT NULL DEFAULT 0,
        discount_total INTEGER NOT NULL DEFAULT 0,
        tax_total INTEGER NOT NULL DEFAULT 0,
        service_charge_total INTEGER NOT NULL DEFAULT 0,
        grand_total INTEGER NOT NULL DEFAULT 0,
        paid_amount INTEGER NOT NULL DEFAULT 0,
        change_amount INTEGER NOT NULL DEFAULT 0,
        payment_status TEXT NOT NULL DEFAULT 'paid',
        order_status TEXT NOT NULL DEFAULT 'completed',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        payment_method TEXT,
        cashier_name TEXT,
        cashier_role TEXT,
        ordered_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT,
        product_name TEXT NOT NULL,
        price INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        discount INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES local_orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE local_order_payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        method TEXT NOT NULL,
        amount INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES local_orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE local_shifts (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        user_role TEXT,
        device_id TEXT,
        outlet_id TEXT,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        opening_cash INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'open',
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE local_products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT,
        category_name TEXT,
        price INTEGER NOT NULL,
        cost INTEGER,
        stock INTEGER,
        sku TEXT,
        image_url TEXT,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE local_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ──────────────────────────────────────────
  // Orders
  // ──────────────────────────────────────────

  Future<void> insertOrder(Map<String, dynamic> order) async {
    await db.insert(
      'local_orders',
      order,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'local_order_items',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertOrderPayments(
      List<Map<String, dynamic>> payments) async {
    final batch = db.batch();
    for (final p in payments) {
      batch.insert(
        'local_order_payments',
        p,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getOrders({
    int limit = 50,
    int offset = 0,
  }) async {
    return db.query(
      'local_orders',
      orderBy: 'ordered_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getOrderById(String id) async {
    final rows =
        await db.query('local_orders', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    return db.query(
      'local_order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<Map<String, dynamic>>> getOrderPayments(
      String orderId) async {
    return db.query(
      'local_order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> updateOrderSyncStatus(String id, String status) async {
    return db.update(
      'local_orders',
      {'sync_status': status, 'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark an order synced and adopt the server-assigned order number (PRD §25.3).
  Future<int> markOrderSynced(String id, [String? serverOrderNumber]) async {
    final values = <String, Object?>{
      'sync_status': 'synced',
      'synced_at': DateTime.now().toIso8601String(),
    };
    if (serverOrderNumber != null && serverOrderNumber.isNotEmpty) {
      values['order_number'] = serverOrderNumber;
    }
    return db.update(
      'local_orders',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateOrderStatus(String id, String orderStatus) async {
    return db.update(
      'local_orders',
      {'order_status': orderStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOrders() async {
    return db.query(
      'local_orders',
      where: "sync_status IN ('pending', 'failed')",
    );
  }

  // ──────────────────────────────────────────
  // Shifts
  // ──────────────────────────────────────────

  Future<void> insertShift(Map<String, dynamic> shift) async {
    await db.insert(
      'local_shifts',
      shift,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    final rows = await db.query(
      'local_shifts',
      where: "status = 'open'",
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> closeShift(
      String id, String closedAt, String note) async {
    return db.update(
      'local_shifts',
      {
        'status': 'closed',
        'closed_at': closedAt,
        'note': note,
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getShiftHistory(
      {int limit = 20}) async {
    return db.query(
      'local_shifts',
      orderBy: 'opened_at DESC',
      limit: limit,
    );
  }

  // ──────────────────────────────────────────
  // Products & Categories (cache)
  // ──────────────────────────────────────────

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'local_products',
        p,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheCategories(
      List<Map<String, dynamic>> categories) async {
    final batch = db.batch();
    for (final c in categories) {
      batch.insert(
        'local_categories',
        c,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    return db.query(
      'local_products',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCachedCategories() async {
    return db.query(
      'local_categories',
      where: 'is_active = 1',
      orderBy: 'sort_order ASC',
    );
  }

  // ──────────────────────────────────────────
  // Settings
  // ──────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    await db.insert(
      'local_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final rows = await db.query(
      'local_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }
}
