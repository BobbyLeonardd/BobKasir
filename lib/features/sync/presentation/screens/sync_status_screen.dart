import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/sync_provider.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncState = ref.watch(syncProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Status Sinkronisasi'),
      ),
      body: Column(
        children: [
          // Connectivity + sync status header
          _SyncHeader(
            isDark: isDark,
            isOnline: isOnline,
            isSyncing: syncState.isSyncing,
            pendingCount: syncState.pendingCount,
            failedCount: syncState.failedCount,
            syncedCount: syncState.syncedCount,
            lastSyncAt: syncState.lastSyncAt,
          ),

          const Divider(height: 1),

          // Queue list
          Expanded(
            child: syncState.queue.isEmpty
                ? const EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Semua data tersinkron',
                    subtitle:
                        'Tidak ada data yang menunggu sinkronisasi.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageH,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: syncState.queue.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _SyncItemTile(
                      item: syncState.queue[i],
                      isDark: isDark,
                    ),
                  ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.pageH),
            child: Column(
              children: [
                if (syncState.hasUnsynced)
                  AppButton(
                    label: syncState.isSyncing
                        ? 'Menyinkronkan...'
                        : 'Sinkronkan Sekarang',
                    onPressed: isOnline && !syncState.isSyncing
                        ? () => ref.read(syncProvider.notifier).syncAll()
                        : null,
                    isLoading: syncState.isSyncing,
                    prefixIcon: Icons.sync_outlined,
                  ),
                if (syncState.failedCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Coba Ulang yang Gagal',
                    onPressed: () =>
                        ref.read(syncProvider.notifier).retryFailed(),
                    variant: AppButtonVariant.ghost,
                    prefixIcon: Icons.replay_outlined,
                  ),
                ],
                if (syncState.syncedCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Bersihkan Riwayat Tersinkron',
                    onPressed: () =>
                        ref.read(syncProvider.notifier).clearSynced(),
                    variant: AppButtonVariant.ghost,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncHeader extends StatelessWidget {
  final bool isDark;
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final int syncedCount;
  final DateTime? lastSyncAt;

  const _SyncHeader({
    required this.isDark,
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    required this.failedCount,
    required this.syncedCount,
    this.lastSyncAt,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      color: surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.info,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isOnline ? AppColors.success : AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (lastSyncAt != null)
                Text(
                  'Terakhir: ${DateHelper.formatDateTime(lastSyncAt!)}',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'Pending',
                      count: pendingCount,
                      color: AppColors.warning,
                      isDark: isDark)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _StatBox(
                      label: 'Gagal',
                      count: failedCount,
                      color: AppColors.danger,
                      isDark: isDark)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _StatBox(
                      label: 'Tersinkron',
                      count: syncedCount,
                      color: AppColors.success,
                      isDark: isDark)),
            ],
          ),
          if (isSyncing) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTextStyles.h2.copyWith(color: color, fontSize: 20),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _SyncItemTile extends StatelessWidget {
  final SyncQueueItem item;
  final bool isDark;

  const _SyncItemTile({required this.item, required this.isDark});

  BadgeType get _badgeType => switch (item.status) {
        SyncItemStatus.pending => BadgeType.warning,
        SyncItemStatus.syncing => BadgeType.info,
        SyncItemStatus.synced => BadgeType.success,
        SyncItemStatus.failed => BadgeType.danger,
      };

  String get _statusLabel => switch (item.status) {
        SyncItemStatus.pending => 'Pending',
        SyncItemStatus.syncing => 'Syncing...',
        SyncItemStatus.synced => 'Tersinkron',
        SyncItemStatus.failed => 'Gagal',
      };

  String get _typeLabel => switch (item.type) {
        SyncItemType.order => 'Transaksi',
        SyncItemType.openBill => 'Open Bill',
        SyncItemType.cancelRequest => 'Cancel Request',
        SyncItemType.refundRequest => 'Refund Request',
        SyncItemType.shift => 'Shift',
        SyncItemType.stockChange => 'Perubahan Stok',
        SyncItemType.auditLog => 'Audit Log',
      };

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  item.localId,
                  style: AppTextStyles.caption,
                ),
                if (item.errorMessage != null)
                  Text(
                    item.errorMessage!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.danger),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                  label: _statusLabel, type: _badgeType),
              if (item.retryCount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Retry: ${item.retryCount}/3',
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
