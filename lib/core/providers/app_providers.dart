import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/openbill_repository.dart';
import '../repositories/reservation_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/receipt_setting_repository.dart';
import '../repositories/notification_repository.dart';
import '../database/database.dart';
import '../services/sync_service.dart';
import '../services/api_client.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final api = ref.watch(apiClientProvider);
  final service = SyncService(db, api);
  ref.onDispose(service.dispose);
  return service;
});
// ─── Auth ────────────────────────────────────────────────────────────────────

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final isOfflineProvider = StateProvider<bool>((ref) => false);

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Async: fetch current user from API
final userProfileProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final user = await repo.getProfile();
  ref.read(currentUserProvider.notifier).state = user;
  return user;
});

// ─── Cart ────────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(ProductModel product) {
    final idx = state.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state);
      updated[idx] = state[idx].copyWith(qty: state[idx].qty + 1);
      state = updated;
    } else {
      state = [...state, CartItem(productId: product.id, productName: product.name, price: product.price)];
    }
  }

  void increment(String productId) {
    state = state.map((i) => i.productId == productId ? i.copyWith(qty: i.qty + 1) : i).toList();
  }

  void decrement(String productId) {
    final item = state.firstWhere((i) => i.productId == productId);
    if (item.qty <= 1) {
      remove(productId);
    } else {
      state = state.map((i) => i.productId == productId ? i.copyWith(qty: i.qty - 1) : i).toList();
    }
  }

  void remove(String productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  void clear() => state = [];

  void loadFromOpenbill(List<CartItem> items) {
    state = List.from(items);
  }

  double get total => state.fold(0, (s, i) => s + i.subtotal);
  int get itemCount => state.fold(0, (s, i) => s + i.qty);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (s, i) => s + i.subtotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (s, i) => s + i.qty);
});

// ─── Products ────────────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Async providers — fetch from API
final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  return ref.read(productRepositoryProvider).getCategories();
});

final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  return ref.read(productRepositoryProvider).getProducts(isActive: true);
});

final filteredProductsProvider = Provider.autoDispose<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  return productsAsync.whenData((products) {
    if (categoryId == null) return products;
    return products.where((p) => p.categoryId == categoryId).toList();
  });
});

// ─── Openbills ───────────────────────────────────────────────────────────────

final openbillsProvider = FutureProvider.autoDispose<List<OpenbillModel>>((ref) async {
  return ref.read(openbillRepositoryProvider).getOpenbills();
});

// ─── Reservations ────────────────────────────────────────────────────────────

final reservationsProvider = FutureProvider.autoDispose<List<ReservationModel>>((ref) async {
  return ref.read(reservationRepositoryProvider).getReservations();
});

// ─── Orders ──────────────────────────────────────────────────────────────────

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  return ref.read(orderRepositoryProvider).getOrders();
});

// ─── Subscription ────────────────────────────────────────────────────────────

enum SubscriptionStatus { trial, active, expired }

class SubscriptionState {
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final String? package;

  const SubscriptionState({
    required this.status,
    this.expiresAt,
    this.package,
  });

  bool get hasFullAccess =>
      status == SubscriptionStatus.trial || status == SubscriptionStatus.active;

  factory SubscriptionState.fromTenant(TenantInfo? tenant) {
    if (tenant == null) {
      return const SubscriptionState(status: SubscriptionStatus.trial);
    }
    final status = switch (tenant.subscriptionStatus) {
      'active' => SubscriptionStatus.active,
      'expired' => SubscriptionStatus.expired,
      _ => SubscriptionStatus.trial,
    };
    return SubscriptionState(
      status: status,
      expiresAt: tenant.subscriptionExpiresAt ?? tenant.trialUntil,
    );
  }
}

final subscriptionProvider = Provider<SubscriptionState>((ref) {
  final user = ref.watch(currentUserProvider);
  return SubscriptionState.fromTenant(user?.tenant);
});

// ─── Users (owner only) ───────────────────────────────────────────────────────

final usersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.read(userRepositoryProvider).getUsers();
});

// ─── Reports ─────────────────────────────────────────────────────────────────

final reportRangeProvider = StateProvider<String>((ref) => 'daily');

final dailyReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(reportRepositoryProvider).getDaily();
});

final compareReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(reportRepositoryProvider).getCompare();
});

final chartDataProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, period) async {
  return ref.read(reportRepositoryProvider).getChartData(period: period);
});

final cashierActivityProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(reportRepositoryProvider).getCashierActivity();
});

// ─── Receipt Settings ─────────────────────────────────────────────────────────

final receiptSettingProvider = FutureProvider.autoDispose<ReceiptSettingModel>((ref) async {
  return ref.read(receiptSettingRepositoryProvider).get();
});

// ─── Notifications ────────────────────────────────────────────────────────────

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.read(notificationRepositoryProvider).getAll();
});
