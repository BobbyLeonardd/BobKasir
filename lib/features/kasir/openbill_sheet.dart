import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/openbill_repository.dart';
import '../../core/models/order_model.dart';
import '../../core/utils/currency.dart';
import '../../widgets/empty_state.dart';

class OpenbillSheet extends ConsumerWidget {
  const OpenbillSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openbills = ref.watch(openbillsProvider).value ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(height: 4, width: 40, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Openbill Aktif (${openbills.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(openbillRepositoryProvider).createOpenbill('Tanpa nama', []);
                      ref.invalidate(openbillsProvider);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Baru'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: openbills.isEmpty
                ? const EmptyState(icon: Icons.receipt_outlined, message: 'Tidak ada bill yang tersimpan.')
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: openbills.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _OpenbillTile(openbill: openbills[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OpenbillTile extends ConsumerWidget {
  final OpenbillModel openbill;
  const _OpenbillTile({required this.openbill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(openbill.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${openbill.items.length} item  •  ${formatRupiah(openbill.total)}', style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).loadFromOpenbill(openbill.items);
              Navigator.pop(context);
            },
            child: const Text('Buka'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus openbill?'),
                  content: const Text('Bill ini akan dihapus.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await ref.read(openbillRepositoryProvider).deleteOpenbill(openbill.id);
                          ref.invalidate(openbillsProvider);
                        } catch (_) {}
                      },
                      child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
