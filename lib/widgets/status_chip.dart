import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/models/order_model.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  factory StatusChip.fromOrderStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.completed => const StatusChip(label: 'Lunas', color: AppColors.success, bgColor: AppColors.successBg),
      OrderStatus.cancelled => const StatusChip(label: 'Cancel', color: AppColors.error, bgColor: AppColors.errorBg),
      OrderStatus.requestCancel => const StatusChip(label: 'Request Cancel', color: AppColors.warning, bgColor: AppColors.warningBg),
      OrderStatus.open => const StatusChip(label: 'Open', color: AppColors.info, bgColor: AppColors.infoBg),
    };
  }

  factory StatusChip.fromReservationStatus(ReservationStatus status) {
    return switch (status) {
      ReservationStatus.pending => const StatusChip(label: 'Pending', color: AppColors.warning, bgColor: AppColors.warningBg),
      ReservationStatus.arrived => const StatusChip(label: 'Arrived', color: AppColors.success, bgColor: AppColors.successBg),
      ReservationStatus.cancelled => const StatusChip(label: 'Cancelled', color: AppColors.onSurface3, bgColor: AppColors.surface3),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
