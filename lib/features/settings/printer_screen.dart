import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});
  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  bool _connected = false;
  bool _cashDrawerOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer & Cash Drawer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.circle, size: 12, color: _connected ? AppColors.success : AppColors.onSurface3),
                  const SizedBox(width: 8),
                  Text(_connected ? 'Terhubung' : 'Tidak Terhubung', style: TextStyle(fontWeight: FontWeight.w600, color: _connected ? AppColors.success : AppColors.onSurface3)),
                ]),
                if (_connected) ...[
                  const SizedBox(height: 4),
                  const Text('Thermal Printer 58mm', style: TextStyle(color: AppColors.onSurface2, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: _connected ? 'Putuskan Koneksi' : 'Scan & Hubungkan',
                  variant: _connected ? AppButtonVariant.secondary : AppButtonVariant.primary,
                  onPressed: () => setState(() => _connected = !_connected),
                ),
                if (_connected) ...[
                  const SizedBox(height: AppSpacing.s3),
                  AppButton(label: 'Test Cetak', variant: AppButtonVariant.secondary, onPressed: () {}),
                ],
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Cash Drawer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                title: const Text('Aktifkan Cash Drawer'),
                subtitle: const Text('Buka drawer otomatis saat checkout', style: TextStyle(fontSize: 13)),
                value: _cashDrawerOn,
                onChanged: (v) => setState(() => _cashDrawerOn = v),
                activeThumbColor: AppColors.primary,
              ),
              if (_cashDrawerOn)
                ListTile(
                  leading: const Icon(Icons.lock_open_outlined, color: AppColors.primary),
                  title: const Text('Buka Cash Drawer Manual'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perintah kick drawer dikirim'))),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ]),
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: const Text('Mendukung printer thermal Bluetooth ESC/POS 58mm/80mm. Pastikan printer sudah dipasangkan di pengaturan Bluetooth device.', style: TextStyle(fontSize: 13, color: AppColors.info)),
          ),
        ],
      ),
    );
  }
}
