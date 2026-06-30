import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/notification_repository.dart';
import '../../core/services/api_client.dart';
import '../../widgets/empty_state.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(notificationRepositoryProvider).markAllRead();
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
              }
            },
            child: const Text('Tandai semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiClient.parseError(e), style: const TextStyle(color: AppColors.error))),
        data: (notifs) => notifs.isEmpty
            ? const EmptyState(icon: Icons.notifications_none_outlined, message: 'Semua sudah terbaca.')
            : ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.isRead ? AppColors.surface2 : AppColors.primaryLight,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: n.isRead ? AppColors.onSurface3 : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.onSurface2)),
                        const SizedBox(height: 2),
                        Text(DateFormat('dd MMM, HH:mm').format(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.onSurface3)),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: n.isRead ? null : () async {
                      try {
                        await ref.read(notificationRepositoryProvider).markRead(n.id);
                        ref.invalidate(notificationsProvider);
                      } catch (_) {}
                    },
                  );
                },
              ),
      ),
    );
  }
}
