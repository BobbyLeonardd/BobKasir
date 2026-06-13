import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/storage/app_storage.dart';
import '../../data/cart_provider.dart';
import '../../domain/checkout_data.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../../orders/data/order_service.dart';
import '../../../sync/data/sync_provider.dart';
import 'receipt_screen.dart';

enum PaymentMethod { cash, qris, transfer, debit, ewallet, other }

extension PaymentMethodExt on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.qris => 'QRIS',
        PaymentMethod.transfer => 'Transfer',
        PaymentMethod.debit => 'Debit',
        PaymentMethod.ewallet => 'E-Wallet',
        PaymentMethod.other => 'Lainnya',
      };
  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.qris => Icons.qr_code_scanner_outlined,
        PaymentMethod.transfer => Icons.account_balance_outlined,
        PaymentMethod.debit => Icons.credit_card_outlined,
        PaymentMethod.ewallet => Icons.wallet_outlined,
        PaymentMethod.other => Icons.more_horiz_outlined,
      };
}

// Model for one payment entry in split payment
class _SplitEntry {
  PaymentMethod method;
  int amount;
  final TextEditingController controller;

  _SplitEntry({required this.method, required this.amount})
      : controller = TextEditingController(
          text: amount > 0 ? amount.toString() : '',
        );

  void dispose() => controller.dispose();
}

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isSplit = false;
  bool _isProcessing = false;

  CheckoutData? _checkout;

  // Single payment
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _cashController = TextEditingController();

  // Split payment entries
  final List<_SplitEntry> _splitEntries = [
    _SplitEntry(method: PaymentMethod.cash, amount: 0),
    _SplitEntry(method: PaymentMethod.qris, amount: 0),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is CheckoutData) _checkout = extra;
  }

  int get _grandTotal =>
      _checkout?.grandTotal ?? ref.read(cartSubtotalProvider);

  int get _cashReceived =>
      CurrencyHelper.parse(_cashController.text);

  int get _change =>
      (_cashReceived - _grandTotal).clamp(0, double.maxFinite.toInt());

  int get _splitTotal =>
      _splitEntries.fold(0, (s, e) => s + e.amount);

  bool get _splitValid => _splitTotal >= _grandTotal;

  @override
  void dispose() {
    _cashController.dispose();
    for (final e in _splitEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _processPayment() async {
    if (!_isSplit) {
      if (_selectedMethod == PaymentMethod.cash &&
          _cashReceived < _grandTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uang diterima kurang dari total tagihan'),
          ),
        );
        return;
      }
    } else {
      if (!_splitValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total pembayaran split belum mencukupi'),
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final grand = _grandTotal;
    final checkout = _checkout;
    final cart = ref.read(cartProvider);
    final user = ref.read(currentUserProvider);

    // Build payment lines + paid/change figures
    final List<PaymentInput> payments;
    final int paidAmount;
    final int changeAmount;
    final String methodLabel;

    if (_isSplit) {
      payments = _splitEntries
          .where((e) => e.amount > 0)
          .map((e) => (method: e.method.label, amount: e.amount))
          .toList();
      paidAmount = _splitTotal;
      changeAmount = (_splitTotal - grand).clamp(0, double.maxFinite.toInt());
      methodLabel = 'Split';
    } else {
      payments = [(method: _selectedMethod.label, amount: grand)];
      paidAmount =
          _selectedMethod == PaymentMethod.cash ? _cashReceived : grand;
      changeAmount = _selectedMethod == PaymentMethod.cash ? _change : 0;
      methodLabel = _selectedMethod.label;
    }

    try {
      final order = await OrderService.createOrder(
        cartItems: cart,
        payments: payments,
        subtotal: checkout?.subtotal ?? ref.read(cartSubtotalProvider),
        discountTotal: checkout?.discountTotal ?? 0,
        taxTotal: checkout?.taxTotal ?? 0,
        serviceChargeTotal: checkout?.serviceChargeTotal ?? 0,
        grandTotal: grand,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        paymentMethod: methodLabel,
        cashierName: user?.name ?? 'Kasir',
        cashierRole: user?.role.label ?? '',
        customerName: checkout?.customerName,
        tableNumber: checkout?.tableNumber,
        note: checkout?.note,
      );

      // Enqueue for server sync (PRD §26) — full payload so the server can
      // recreate the order and assign a final order number.
      ref.read(syncProvider.notifier).enqueue(
            SyncQueueItem(
              syncId: 'sync-${order.id}',
              localId: order.id,
              deviceId: AppStorage.instance.deviceId ?? 'unknown',
              type: SyncItemType.order,
              payload: order.toSyncPayload(),
            ),
          );

      final receipt = ReceiptData(
        orderNumber: order.orderNumber,
        orderedAt: order.orderedAt,
        cashierName: order.cashierName,
        customerName: order.customerName,
        tableNumber: order.tableNumber,
        note: order.note,
        items: order.itemMaps,
        subtotal: order.subtotal,
        discountTotal: order.discountTotal,
        taxTotal: order.taxTotal,
        serviceTotal: order.serviceChargeTotal,
        grandTotal: order.grandTotal,
        paidAmount: order.paidAmount,
        changeAmount: order.changeAmount,
        paymentMethod: order.paymentMethod,
      );

      if (!mounted) return;
      ref.read(cartProvider.notifier).clear();
      context.go(AppRoutes.receipt, extra: receipt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pembayaran'),
        actions: [
          // Split payment toggle
          TextButton.icon(
            onPressed: () => setState(() {
              _isSplit = !_isSplit;
              if (_isSplit) {
                // Pre-fill first entry with full amount
                _splitEntries[0].amount = 0;
                _splitEntries[0].controller.clear();
              }
            }),
            icon: Icon(
              _isSplit
                  ? Icons.call_merge_outlined
                  : Icons.call_split_outlined,
              size: 18,
            ),
            label: Text(
              _isSplit ? 'Normal' : 'Split',
              style: AppTextStyles.buttonSmall,
            ),
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.champagneGold
                  : AppColors.brushedGold,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TotalDisplay(amount: _grandTotal, isDark: isDark),
            const SizedBox(height: AppSpacing.lg),

            if (!_isSplit) ...[
              _buildSinglePayment(isDark),
            ] else ...[
              _buildSplitPayment(isDark),
            ],

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isProcessing
                  ? 'Memproses...'
                  : 'Proses Pembayaran',
              onPressed: _processPayment,
              isLoading: _isProcessing,
              prefixIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePayment(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'METODE PEMBAYARAN',
          style: AppTextStyles.label.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.ashGray,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaymentMethodGrid(
          selected: _selectedMethod,
          isDark: isDark,
          onSelect: (m) => setState(() => _selectedMethod = m),
        ),
        if (_selectedMethod == PaymentMethod.cash) ...[
          const SizedBox(height: AppSpacing.lg),
          _CashInput(
            controller: _cashController,
            grandTotal: _grandTotal,
            change: _change,
            isDark: isDark,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildSplitPayment(bool isDark) {
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent =
        isDark ? AppColors.champagneGold : AppColors.brushedGold;
    final remaining = _grandTotal - _splitTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SPLIT PAYMENT',
              style: AppTextStyles.label.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.ashGray,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _splitEntries.add(
                    _SplitEntry(
                        method: PaymentMethod.cash, amount: 0),
                  );
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text('Tambah', style: AppTextStyles.buttonSmall),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Remaining indicator
        if (remaining > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              'Sisa: ${CurrencyHelper.format(remaining)}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.warning),
              textAlign: TextAlign.center,
            ),
          )
        else if (_splitTotal > _grandTotal)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              'Kembalian: ${CurrencyHelper.format(_splitTotal - _grandTotal)}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ),

        ..._splitEntries.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PaymentMethodGrid(
                        selected: e.method,
                        isDark: isDark,
                        onSelect: (m) =>
                            setState(() => _splitEntries[i].method = m),
                        compact: true,
                      ),
                    ),
                    if (_splitEntries.length > 2)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: AppColors.danger, size: 20),
                        onPressed: () {
                          _splitEntries[i].dispose();
                          setState(() => _splitEntries.removeAt(i));
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: e.controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  onChanged: (v) {
                    setState(
                        () => _splitEntries[i].amount =
                            int.tryParse(v) ?? 0);
                  },
                  decoration: InputDecoration(
                    labelText: 'Jumlah ${e.method.label}',
                    prefixText: 'Rp ',
                  ),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────

class _TotalDisplay extends StatelessWidget {
  final int amount;
  final bool isDark;
  const _TotalDisplay({required this.amount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL TAGIHAN',
            style: AppTextStyles.label.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.ashGray,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyHelper.format(amount),
            style: AppTextStyles.displayMedium.copyWith(
              color: isDark
                  ? AppColors.champagneGold
                  : AppColors.brushedGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodGrid extends StatelessWidget {
  final PaymentMethod selected;
  final bool isDark;
  final ValueChanged<PaymentMethod> onSelect;
  final bool compact;

  const _PaymentMethodGrid({
    required this.selected,
    required this.isDark,
    required this.onSelect,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.champagneGold : AppColors.charcoal;
    final inactiveBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.xs,
      mainAxisSpacing: AppSpacing.xs,
      childAspectRatio: compact ? 2.2 : 1.4,
      children: PaymentMethod.values.map((m) {
        final isSelected = m == selected;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.08)
                  : inactiveBg,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? activeColor : border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  m.icon,
                  size: compact ? 16 : 22,
                  color: isSelected
                      ? activeColor
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.ashGray),
                ),
                if (!compact) const SizedBox(height: 4),
                Text(
                  m.label,
                  style: AppTextStyles.buttonSmall.copyWith(
                    fontSize: compact ? 10 : 12,
                    color: isSelected
                        ? activeColor
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.ashGray),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CashInput extends StatelessWidget {
  final TextEditingController controller;
  final int grandTotal;
  final int change;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CashInput({
    required this.controller,
    required this.grandTotal,
    required this.change,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UANG DITERIMA',
          style: AppTextStyles.label.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.ashGray,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah uang',
            prefixText: 'Rp ',
            prefixStyle: AppTextStyles.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        // Quick amount shortcuts
        const SizedBox(height: AppSpacing.sm),
        _QuickAmounts(
          grandTotal: grandTotal,
          isDark: isDark,
          onSelect: (v) {
            controller.text = v.toString();
            onChanged(v.toString());
          },
        ),
        if (change > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kembalian',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.success),
                ),
                Text(
                  CurrencyHelper.format(change),
                  style: AppTextStyles.priceTotal
                      .copyWith(color: AppColors.success, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAmounts extends StatelessWidget {
  final int grandTotal;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _QuickAmounts({
    required this.grandTotal,
    required this.isDark,
    required this.onSelect,
  });

  List<int> get _amounts {
    // Round up to common cash values
    final values = <int>[];
    int roundUp(int v, int factor) => (v / factor).ceil() * factor;
    values.add(grandTotal); // exact
    values.add(roundUp(grandTotal, 5000));
    values.add(roundUp(grandTotal, 10000));
    values.add(roundUp(grandTotal, 50000));
    return values.toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _amounts.map((a) {
          return GestureDetector(
            onTap: () => onSelect(a),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: border),
              ),
              child: Text(
                CurrencyHelper.format(a),
                style: AppTextStyles.buttonSmall.copyWith(
                  color: isDark
                      ? AppColors.champagneGold
                      : AppColors.brushedGold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
