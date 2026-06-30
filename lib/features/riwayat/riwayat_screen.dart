import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/order_model.dart';
import '../../core/utils/currency.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});
  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  OrderStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider).value ?? [];
    final filtered = _statusFilter == null ? orders : orders.where((o) => o.status == _statusFilter).toList();
    final fmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Semua'), selected: _statusFilter == null, onSelected: (_) => setState(() => _statusFilter = null))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Lunas'), selected: _statusFilter == OrderStatus.completed, onSelected: (_) => setState(() => _statusFilter = OrderStatus.completed))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Cancel'), selected: _statusFilter == OrderStatus.cancelled, onSelected: (_) => setState(() => _statusFilter = OrderStatus.cancelled))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Request Cancel'), selected: _statusFilter == OrderStatus.requestCancel, onSelected: (_) => setState(() => _statusFilter = OrderStatus.requestCancel))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, message: 'Belum ada transaksi hari ini.')
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final o = filtered[i];
                      final names = o.items.take(2).map((x) => x.productName).join(', ');
                      final more = o.items.length > 2 ? ' (+${o.items.length - 2})' : '';
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(children: [
                            Text(o.id, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Text('  •  ', style: TextStyle(color: AppColors.onSurface3)),
                            Text(fmt.format(o.createdAt), style: const TextStyle(color: AppColors.onSurface2)),
                            const Text('  •  ', style: TextStyle(color: AppColors.onSurface3)),
                            Text(o.cashierName, style: const TextStyle(color: AppColors.onSurface2)),
                          ]),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$names$more', style: const TextStyle(fontSize: 13, color: AppColors.onSurface2)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text(formatRupiah(o.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                StatusChip.fromOrderStatus(o.status),
                              ]),
                            ],
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.print_outlined, size: 20), onPressed: () {}, tooltip: 'Cetak'),
                            const Icon(Icons.chevron_right),
                          ]),
                          onTap: () => context.push('/riwayat/${o.id.replaceAll('#', '')}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
