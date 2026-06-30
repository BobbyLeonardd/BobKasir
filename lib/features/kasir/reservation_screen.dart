// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/reservation_repository.dart';
import '../../core/models/order_model.dart';
import '../../core/services/api_client.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_button.dart';

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({super.key});
  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  ReservationStatus? _filter;

  void _showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddReservationSheet(onSaved: () => ref.invalidate(reservationsProvider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationsProvider);
    final all = reservationsAsync.value ?? [];
    final reservations = _filter == null ? all : all.where((r) => r.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservasi'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddForm),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Semua'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null))),
                ...ReservationStatus.values.map((s) {
                  final labels = {ReservationStatus.pending: 'Pending', ReservationStatus.arrived: 'Arrived', ReservationStatus.cancelled: 'Cancelled'};
                  return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(labels[s]!), selected: _filter == s, onSelected: (_) => setState(() => _filter = s)));
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: reservationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(ApiClient.parseError(e), style: const TextStyle(color: AppColors.error))),
              data: (_) => reservations.isEmpty
                  ? EmptyState(icon: Icons.calendar_today_outlined, message: 'Tidak ada reservasi.', actionLabel: '+ Buat Reservasi', onAction: _showAddForm)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      itemCount: reservations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReservationCard(reservation: reservations[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('HH:mm');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.onSurface2),
              const SizedBox(width: 6),
              Text(fmt.format(reservation.arrivalTime), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(reservation.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (reservation.tableNumber != null) ...[
                const Text('  •  ', style: TextStyle(color: AppColors.onSurface3)),
                Text(reservation.tableNumber!, style: const TextStyle(color: AppColors.onSurface2)),
              ],
              const Spacer(),
              StatusChip.fromReservationStatus(reservation.status),
            ]),
            if (reservation.notes != null) ...[
              const SizedBox(height: 6),
              Text('"${reservation.notes}"', style: const TextStyle(color: AppColors.onSurface2, fontSize: 13, fontStyle: FontStyle.italic)),
            ],
            if (reservation.status == ReservationStatus.pending) ...[
              const SizedBox(height: 10),
              AppButton(
                label: 'Konversi ke Order',
                fullWidth: false,
                onPressed: () async {
                  try {
                    await ref.read(reservationRepositoryProvider).arrive(reservation.id);
                    ref.invalidate(reservationsProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ApiClient.parseError(e))));
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddReservationSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddReservationSheet({required this.onSaved});

  @override
  ConsumerState<_AddReservationSheet> createState() => _AddReservationSheetState();
}

class _AddReservationSheetState extends ConsumerState<_AddReservationSheet> {
  final _nameCtrl = TextEditingController();
  final _tableCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _arrivalTime = DateTime.now().add(const Duration(hours: 1));
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _tableCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buat Reservasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Customer')),
          const SizedBox(height: AppSpacing.s3),
          TextField(controller: _tableCtrl, decoration: const InputDecoration(labelText: 'Nomor Meja')),
          const SizedBox(height: AppSpacing.s3),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Waktu Datang'),
            subtitle: Text(DateFormat('dd MMM HH:mm').format(_arrivalTime)),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_arrivalTime));
              if (t != null) setState(() => _arrivalTime = DateTime(_arrivalTime.year, _arrivalTime.month, _arrivalTime.day, t.hour, t.minute));
            },
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Keterangan (opsional)')),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: _loading ? 'Menyimpan...' : 'Simpan Reservasi',
            onPressed: _loading ? null : () async {
              if (_nameCtrl.text.isEmpty) return;
              setState(() => _loading = true);
              try {
                await ref.read(reservationRepositoryProvider).createReservation(
                  customerName: _nameCtrl.text.trim(),
                  arrivalTime: _arrivalTime,
                  tableNumber: _tableCtrl.text.isEmpty ? null : _tableCtrl.text.trim(),
                  notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
                );
                widget.onSaved();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
