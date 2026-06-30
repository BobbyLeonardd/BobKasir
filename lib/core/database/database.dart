import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [CategoriesTable, ProductsTable, OrdersTable, OrderItemsTable, OrderPaymentsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // -- Categories & Products Cache --

  Future<void> cacheCategories(List<CategoriesTableCompanion> categories) async {
    await batch((batch) {
      batch.insertAll(categoriesTable, categories, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<CategoriesTableData>> getCategories() {
    return select(categoriesTable).get();
  }

  Future<void> cacheProducts(List<ProductsTableCompanion> products) async {
    await batch((batch) {
      batch.insertAll(productsTable, products, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<ProductsTableData>> getProducts() {
    return select(productsTable).get();
  }

  // -- Orders --

  Future<void> insertOrderWithDetails(
    OrdersTableCompanion order,
    List<OrderItemsTableCompanion> items,
    List<OrderPaymentsTableCompanion> payments,
  ) async {
    return transaction(() async {
      await into(ordersTable).insert(order, mode: InsertMode.insertOrReplace);
      await batch((batch) {
        batch.insertAll(orderItemsTable, items);
        batch.insertAll(orderPaymentsTable, payments);
      });
    });
  }

  Future<List<OrdersTableData>> getPendingOrders() {
    return (select(ordersTable)..where((t) => t.syncStatus.equals(0))).get();
  }

  Future<List<OrderItemsTableData>> getOrderItems(String orderId) {
    return (select(orderItemsTable)..where((t) => t.orderId.equals(orderId))).get();
  }

  Future<List<OrderPaymentsTableData>> getOrderPayments(String orderId) {
    return (select(orderPaymentsTable)..where((t) => t.orderId.equals(orderId))).get();
  }

  Future<void> markOrderAsSynced(String id) {
    return (update(ordersTable)..where((t) => t.id.equals(id))).write(
      const OrdersTableCompanion(syncStatus: Value(1)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bobkasir_db.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
