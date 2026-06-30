import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/order_model.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/utils/currency.dart';
import '../../widgets/app_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _customerCtrl = TextEditingController();
  final _tableCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  final _cashCtrl = TextEditingController();
  bool _splitBill = false;
  final List<_SplitEntry> _splits = [_SplitEntry()];
  bool _loading = false;

  @override
  void dispose() {
    _customerCtrl.dispose(); _tableCtrl.dispose(); _notesCtrl.dispose(); _cashCtrl.dispose();
    for (final s in _splits) { s.dispose(); }
    super.dispose();
  }

  double get _total => ref.read(cartTotalProvider);
  double get _paid => double.tryParse(_cashCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  double get _change => _paid - _total;

  double get _splitTotal => _splits.fold(0, (s, e) => s + (double.tryParse(e.amountCtrl.text.replaceAll('.', '')) ?? 0));

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _customerCtrl, decoration: const InputDecoration(labelText: 'Nama Customer (opsional)')),
            const SizedBox(height: AppSpacing.s4),
            TextField(controller: _tableCtrl, decoration: const InputDecoration(labelText: 'Nomor Meja (opsional)')),
            const SizedBox(height: AppSpacing.s4),
            TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Keterangan (opsional)')),
            const SizedBox(height: AppSpacing.s6),
            const Text('Item Pesanan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.s3),
            ...cart.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text('${i.productName} × ${i.qty}')),
                Text(formatRupiah(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            )),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(formatRupiah(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            const SizedBox(height: AppSpacing.s6),
            const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.s3),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: PaymentMethod.values.map((m) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m.label),
                    selected: _method == m && !_splitBill,
                    onSelected: (_) => setState(() { _method = m; _splitBill = false; }),
                  ),
                )).toList(),
              ),
            ),
            if (_method == PaymentMethod.cash && !_splitBill) ...[
              const SizedBox(height: AppSpacing.s4),
              TextField(
                controller: _cashCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal Bayar', prefixText: 'Rp '),
                onChanged: (_) => setState(() {}),
              ),
              if (_cashCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Kembalian', style: TextStyle(color: AppColors.onSurface2)),
                  Text(formatRupiah(_change.clamp(0, double.infinity)), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                ]),
              ],
            ],
            const SizedBox(height: AppSpacing.s4),
            TextButton.icon(
              onPressed: () => setState(() => _splitBill = !_splitBill),
              icon: Icon(_splitBill ? Icons.expand_less : Icons.call_split, size: 18),
              label: Text(_splitBill ? 'Tutup Split Bill' : 'Split Bill'),
              style: TextButton.styleFrom(foregroundColor: AppColors.onSurface2),
            ),
            if (_splitBill) ...[
              ..._splits.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Expanded(child: DropdownButtonFormField<PaymentMethod>(
                    // ignore: deprecated_member_use
                    value: e.value.method,
                    decoration: const InputDecoration(labelText: 'Metode', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
                    onChanged: (v) => setState(() => e.value.method = v!),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: e.value.amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
                    onChanged: (_) => setState(() {}),
                  )),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: _splits.length > 1 ? () => setState(() => _splits.removeAt(e.key)) : null,
                  ),
                ]),
              )),
              TextButton.icon(
                onPressed: () => setState(() => _splits.add(_SplitEntry())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Bagian'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Sisa', style: TextStyle(color: AppColors.onSurface2)),
                  Text(
                    formatRupiah((total - _splitTotal).clamp(0, double.infinity)),
                    style: TextStyle(fontWeight: FontWeight.w600, color: (total - _splitTotal).abs() < 1 ? AppColors.success : AppColors.warning),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: AppSpacing.s8),
              AppButton(
              label: 'Konfirmasi Pembayaran',
              loading: _loading,
              onPressed: () async {
                setState(() => _loading = true);
                
                final cartItems = ref.read(cartProvider);
                final user = ref.read(currentUserProvider);
                
                final payments = <SplitPayment>[];
                if (_splitBill) {
                  for (final s in _splits) {
                    final amt = double.tryParse(s.amountCtrl.text.replaceAll('.', '')) ?? 0;
                    if (amt > 0) payments.add(SplitPayment(method: s.method, amount: amt));
                  }
                } else {
                  payments.add(SplitPayment(method: _method, amount: _paid, change: _change.clamp(0, double.infinity)));
                }

                final navigator = GoRouter.of(context);
                final scaffold = ScaffoldMessenger.of(context);

                try {
                  await ref.read(orderRepositoryProvider).createOrder(
                    tenantId: user?.tenantId ?? 't1',
                    userId: user?.id ?? 'usr_1',
                    cashierName: user?.name ?? 'Kasir',
                    items: cartItems,
                    payments: payments,
                    customerName: _customerCtrl.text.isEmpty ? null : _customerCtrl.text,
                    tableNumber: _tableCtrl.text.isEmpty ? null : _tableCtrl.text,
                    notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                  );
                  
                  if (!mounted) return;
                  ref.read(cartProvider.notifier).clear();
                  navigator.go('/receipt');
                } catch (e) {
                  if (!mounted) return;
                  scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitEntry {
  PaymentMethod method = PaymentMethod.cash;
  final amountCtrl = TextEditingController();
  void dispose() => amountCtrl.dispose();
}
