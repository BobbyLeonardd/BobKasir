import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/reservation_provider.dart';
import '../../domain/reservation_model.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../auth/domain/user_model.dart';

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({super.key});

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reservations = ref.watch(reservationProvider);
    final role = ref.watch(currentRoleProvider) ?? UserRole.karyawan;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final today = reservations
        .where((r) =>
            r.reservationDate.year == DateTime.now().year &&
            r.reservationDate.month == DateTime.now().month &&
            r.reservationDate.day == DateTime.now().day)
        .toList()
      ..sort((a, b) => a.reservationDateTime.compareTo(b.reservationDateTime));

    final upcoming = reservations
        .where((r) =>
            r.reservationDateTime.isAfter(DateTime.now()) &&
            r.status != ReservationStatus.cancelled &&
            r.status != ReservationStatus.noShow)
        .toList()
      ..sort((a, b) => a.reservationDateTime.compareTo(b.reservationDateTime));

    final all = [...reservations]
      ..sort((a, b) => b.reservationDateTime.compareTo(a.reservationDateTime));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reservasi'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: AppTextStyles.buttonSmall,
          labelColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
          indicatorColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: border,
          tabs: [
            Tab(text: 'Hari Ini (${today.length})'),
            const Tab(text: 'Mendatang'),
            const Tab(text: 'Semua'),
          ],
        ),
      ),
      floatingActionButton: (role == UserRole.owner || role == UserRole.manager)
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context, ref),
              backgroundColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
              child: Icon(Icons.add, color: isDark ? AppColors.obsidian : Colors.white),
            )
          : null,
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ReservationList(reservations: today, isDark: isDark, role: role),
          _ReservationList(reservations: upcoming, isDark: isDark, role: role),
          _ReservationList(reservations: all, isDark: isDark, role: role),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => _ReservationFormSheet(
        onSave: (r) {
          ref.read(reservationProvider.notifier).add(r);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ReservationList extends ConsumerWidget {
  final List<ReservationModel> reservations;
  final bool isDark;
  final UserRole role;

  const _ReservationList({
    required this.reservations,
    required this.isDark,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reservations.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: 'Belum ada reservasi',
        subtitle: 'Reservasi yang dibuat akan muncul di sini.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: AppSpacing.md,
      ),
      itemCount: reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _ReservationCard(
        reservation: reservations[i],
        isDark: isDark,
        role: role,
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  final ReservationModel reservation;
  final bool isDark;
  final UserRole role;

  const _ReservationCard({
    required this.reservation,
    required this.isDark,
    required this.role,
  });

  BadgeType get _badgeType => switch (reservation.status) {
    ReservationStatus.pending => BadgeType.warning,
    ReservationStatus.confirmed => BadgeType.info,
    ReservationStatus.arrived => BadgeType.success,
    ReservationStatus.completed => BadgeType.success,
    ReservationStatus.cancelled => BadgeType.danger,
    ReservationStatus.noShow => BadgeType.danger,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reservation.customerName,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 15,
                ),
              ),
              StatusBadge(label: reservation.status.label, type: _badgeType),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.access_time_outlined, size: 13, color: AppColors.ashGray),
              const SizedBox(width: 4),
              Text(
                '${DateHelper.formatDate(reservation.reservationDate)} · ${reservation.reservationTime.format(context)}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.people_outline, size: 13, color: AppColors.ashGray),
              const SizedBox(width: 4),
              Text('${reservation.partySize} orang', style: AppTextStyles.caption),
            ],
          ),
          if (reservation.tableNumber?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.table_restaurant_outlined, size: 13, color: AppColors.ashGray),
                const SizedBox(width: 4),
                Text('Meja ${reservation.tableNumber}', style: AppTextStyles.caption),
              ],
            ),
          ],
          if (reservation.phone?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 13, color: AppColors.ashGray),
                const SizedBox(width: 4),
                Text(reservation.phone!, style: AppTextStyles.caption),
              ],
            ),
          ],
          if (reservation.note?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('📝 ${reservation.note}', style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Action buttons
          Row(
            children: [
              if (reservation.status == ReservationStatus.pending &&
                  (role == UserRole.owner || role == UserRole.manager))
                _ActionBtn(
                  label: 'Konfirmasi',
                  color: AppColors.success,
                  onTap: () => ref.read(reservationProvider.notifier)
                      .updateStatus(reservation.id, ReservationStatus.confirmed),
                ),
              if (reservation.status == ReservationStatus.confirmed) ...[
                _ActionBtn(
                  label: 'Hadir',
                  color: AppColors.success,
                  onTap: () => ref.read(reservationProvider.notifier)
                      .updateStatus(reservation.id, ReservationStatus.arrived),
                ),
                const SizedBox(width: AppSpacing.xs),
                _ActionBtn(
                  label: 'No Show',
                  color: AppColors.warning,
                  onTap: () => ref.read(reservationProvider.notifier)
                      .updateStatus(reservation.id, ReservationStatus.noShow),
                ),
              ],
              if (reservation.status == ReservationStatus.arrived)
                _ActionBtn(
                  label: 'Selesai',
                  color: AppColors.info,
                  onTap: () => ref.read(reservationProvider.notifier)
                      .updateStatus(reservation.id, ReservationStatus.completed),
                ),
              const Spacer(),
              if (reservation.status != ReservationStatus.cancelled &&
                  reservation.status != ReservationStatus.completed &&
                  (role == UserRole.owner || role == UserRole.manager))
                TextButton(
                  onPressed: () => ref.read(reservationProvider.notifier)
                      .updateStatus(reservation.id, ReservationStatus.cancelled),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: AppTextStyles.buttonSmall.copyWith(color: color)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Form sheet untuk tambah/edit reservasi
// ─────────────────────────────────────────────
class _ReservationFormSheet extends StatefulWidget {
  final void Function(ReservationModel) onSave;

  const _ReservationFormSheet({required this.onSave});

  @override
  State<_ReservationFormSheet> createState() => _ReservationFormSheetState();
}

class _ReservationFormSheetState extends State<_ReservationFormSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _tableCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _partyCtrl = TextEditingController(text: '2');
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _tableCtrl.dispose();
    _noteCtrl.dispose();
    _partyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.md,
        AppSpacing.pageH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Tambah Reservasi', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Customer *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor HP'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tanggal', style: AppTextStyles.bodySmall),
                    subtitle: Text(DateHelper.formatDate(_date),
                        style: AppTextStyles.bodyMedium),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Jam', style: AppTextStyles.bodySmall),
                    subtitle: Text(_time.format(context),
                        style: AppTextStyles.bodyMedium),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _partyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Tamu'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _tableCtrl,
                    decoration: const InputDecoration(labelText: 'Nomor Meja'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isEmpty) return;
                  widget.onSave(ReservationModel(
                    customerName: _nameCtrl.text,
                    phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
                    reservationDate: _date,
                    reservationTime: _time,
                    partySize: int.tryParse(_partyCtrl.text) ?? 2,
                    tableNumber: _tableCtrl.text.isEmpty ? null : _tableCtrl.text,
                    note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                  ));
                },
                child: Text('Buat Reservasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
