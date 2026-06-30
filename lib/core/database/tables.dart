import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get stock => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class OrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get userId => text()();
  TextColumn get cashierName => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get total => real()();
  TextColumn get status => text()();
  TextColumn get localId => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0 = pending, 1 = synced
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OrderItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text().references(OrdersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get price => real()();
  IntColumn get qty => integer()();
  TextColumn get notes => text().nullable()();
}

class OrderPaymentsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text().references(OrdersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get method => text()();
  RealColumn get amount => real()();
  RealColumn get changeAmount => real().withDefault(const Constant(0))();
  IntColumn get splitIndex => integer()();
}
