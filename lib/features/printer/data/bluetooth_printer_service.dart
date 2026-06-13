import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/constants/app_constants.dart';

/// Bluetooth thermal printer service.
/// Supports all common ESC/POS printers:
/// Epson, Xprinter, RONGTA, MUNBYN, iDPRT, POS-5890, etc.
///
/// Uses blue_thermal_printer which handles the low-level Bluetooth
/// Classic SPP (Serial Port Profile) connection used by thermal printers.

enum PrinterStatus { disconnected, connecting, connected, error }

class BluetoothPrinterState {
  final PrinterStatus status;
  final BluetoothDevice? connectedDevice;
  final List<BluetoothDevice> scannedDevices;
  final bool isScanning;
  final String paperSize; // '58mm' or '80mm'
  final String? errorMessage;

  const BluetoothPrinterState({
    this.status = PrinterStatus.disconnected,
    this.connectedDevice,
    this.scannedDevices = const [],
    this.isScanning = false,
    this.paperSize = '80mm',
    this.errorMessage,
  });

  bool get isConnected => status == PrinterStatus.connected;
  int get charsPerLine => paperSize == '58mm'
      ? AppConstants.paper58mmChars
      : AppConstants.paper80mmChars;

  BluetoothPrinterState copyWith({
    PrinterStatus? status,
    BluetoothDevice? connectedDevice,
    List<BluetoothDevice>? scannedDevices,
    bool? isScanning,
    String? paperSize,
    String? errorMessage,
    bool clearDevice = false,
    bool clearError = false,
  }) =>
      BluetoothPrinterState(
        status: status ?? this.status,
        connectedDevice: clearDevice ? null : (connectedDevice ?? this.connectedDevice),
        scannedDevices: scannedDevices ?? this.scannedDevices,
        isScanning: isScanning ?? this.isScanning,
        paperSize: paperSize ?? this.paperSize,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class BluetoothPrinterNotifier extends Notifier<BluetoothPrinterState> {
  final _bt = BlueThermalPrinter.instance;

  @override
  BluetoothPrinterState build() {
    final storage = AppStorage.instance;
    return BluetoothPrinterState(
      paperSize: storage.paperSize,
    );
  }

  // ──────────────────────────────────────────
  // Connection
  // ──────────────────────────────────────────

  Future<void> scan() async {
    state = state.copyWith(isScanning: true, scannedDevices: []);
    try {
      final devices = await _bt.getBondedDevices();
      state = state.copyWith(
        isScanning: false,
        scannedDevices: devices,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Gagal scan: $e',
      );
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    state = state.copyWith(
      status: PrinterStatus.connecting,
      connectedDevice: device,
      clearError: true,
    );
    try {
      await _bt.connect(device);
      await AppStorage.instance.savePrinter(
        device.name ?? 'Unknown Printer',
        device.address ?? '',
      );
      state = state.copyWith(
        status: PrinterStatus.connected,
        connectedDevice: device,
      );
    } catch (e) {
      state = state.copyWith(
        status: PrinterStatus.error,
        errorMessage: 'Gagal connect: $e',
        clearDevice: true,
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _bt.disconnect();
    } catch (_) {}
    state = state.copyWith(
      status: PrinterStatus.disconnected,
      clearDevice: true,
    );
  }

  Future<void> reconnect() async {
    if (state.connectedDevice != null) {
      await connect(state.connectedDevice!);
    }
  }

  Future<void> setPaperSize(String size) async {
    await AppStorage.instance.savePaperSize(size);
    state = state.copyWith(paperSize: size);
  }

  // ──────────────────────────────────────────
  // Printing
  // ──────────────────────────────────────────

  Future<void> printTest() async {
    if (!await _ensureConnected()) return;
    final w = state.charsPerLine;
    await _bt.printNewLine();
    await _bt.printCustom(_center('** TEST CETAK **', w), 2, 1);
    await _bt.printCustom(_center('BobKasir', w), 2, 1);
    await _bt.printCustom('=' * w, 2, 1);
    await _bt.printCustom('Lebar kertas : ${state.paperSize}', 2, 1);
    await _bt.printCustom('Karakter/baris: $w', 2, 1);
    await _bt.printCustom('=' * w, 2, 1);
    await _bt.printCustom(_center('Printer OK!', w), 2, 1);
    await _bt.printNewLine();
    await _bt.printNewLine();
    await _bt.printNewLine();
    await _bt.printNewLine();
  }

  Future<void> printCustomerReceipt({
    required String businessName,
    required String address,
    required String phone,
    required String orderNumber,
    required DateTime orderedAt,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required int discountTotal,
    required int taxTotal,
    required int serviceTotal,
    required int grandTotal,
    required int paidAmount,
    required int changeAmount,
    required String paymentMethod,
    String? customerName,
    String? tableNumber,
    String? footer,
  }) async {
    if (!await _ensureConnected()) return;
    final w = state.charsPerLine;

    await _bt.printNewLine();
    // Header
    await _bt.printCustom(_center(businessName, w), 2, 1);
    if (address.isNotEmpty) {
      await _bt.printCustom(_center(address, w), 1, 1);
    }
    if (phone.isNotEmpty) {
      await _bt.printCustom(_center(phone, w), 1, 1);
    }
    await _bt.printCustom('=' * w, 1, 1);

    // Order info
    await _bt.printCustom('No: $orderNumber', 1, 1);
    await _bt.printCustom('Tgl: ${_fmtDate(orderedAt)}', 1, 1);
    await _bt.printCustom('Kasir: $cashierName', 1, 1);
    if (customerName != null && customerName.isNotEmpty) {
      await _bt.printCustom('Cust: $customerName', 1, 1);
    }
    if (tableNumber != null && tableNumber.isNotEmpty) {
      await _bt.printCustom('Meja: $tableNumber', 1, 1);
    }
    await _bt.printCustom('-' * w, 1, 1);

    // Items
    for (final item in items) {
      final name = item['name'] as String? ?? '';
      final qty = item['qty'] as int? ?? 1;
      final amount = item['subtotal'] as int? ?? 0;
      final note = item['note'] as String? ?? '';
      await _bt.printCustom('$qty x $name', 1, 1);
      await _bt.printCustom(_rightAlign(_fmtCurrency(amount), w), 1, 1);
      if (note.isNotEmpty) {
        await _bt.printCustom('   * $note', 1, 1);
      }
    }
    await _bt.printCustom('-' * w, 1, 1);

    // Totals
    await _bt.printCustom(_pair('Subtotal', _fmtCurrency(subtotal), w), 1, 1);
    if (discountTotal > 0) {
      await _bt.printCustom(_pair('Diskon', '- ${_fmtCurrency(discountTotal)}', w), 1, 1);
    }
    if (taxTotal > 0) {
      await _bt.printCustom(_pair('Pajak', _fmtCurrency(taxTotal), w), 1, 1);
    }
    if (serviceTotal > 0) {
      await _bt.printCustom(_pair('Service', _fmtCurrency(serviceTotal), w), 1, 1);
    }
    await _bt.printCustom('=' * w, 1, 1);
    await _bt.printCustom(_pair('TOTAL', _fmtCurrency(grandTotal), w), 2, 1);
    await _bt.printCustom('=' * w, 1, 1);
    await _bt.printCustom(_pair(paymentMethod, _fmtCurrency(paidAmount), w), 1, 1);
    if (changeAmount > 0) {
      await _bt.printCustom(_pair('Kembalian', _fmtCurrency(changeAmount), w), 1, 1);
    }
    await _bt.printCustom('=' * w, 1, 1);

    // Footer
    final footerText = footer?.isNotEmpty == true ? footer! : 'Terima kasih!';
    await _bt.printCustom(_center(footerText, w), 1, 1);
    await _bt.printNewLine();
    await _bt.printNewLine();
    await _bt.printNewLine();
    await _bt.printNewLine();
  }

  Future<void> printKitchenReceipt({
    required String orderNumber,
    required DateTime orderedAt,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    String? tableNumber,
    String? customerName,
    String? note,
  }) async {
    if (!await _ensureConnected()) return;
    final w = state.charsPerLine;

    await _bt.printNewLine();
    await _bt.printCustom(_center('** DAPUR **', w), 2, 1);
    await _bt.printCustom('No: $orderNumber', 1, 1);
    await _bt.printCustom('Tgl: ${_fmtDate(orderedAt)}', 1, 1);
    await _bt.printCustom('Kasir: $cashierName', 1, 1);
    if (tableNumber != null && tableNumber.isNotEmpty) {
      await _bt.printCustom('Meja: $tableNumber', 2, 1);
    }
    if (customerName != null && customerName.isNotEmpty) {
      await _bt.printCustom('Cust: $customerName', 1, 1);
    }
    await _bt.printCustom('=' * w, 1, 1);

    for (final item in items) {
      final name = item['name'] as String? ?? '';
      final qty = item['qty'] as int? ?? 1;
      final itemNote = item['note'] as String? ?? '';
      await _bt.printCustom('$qty x $name', 2, 1);
      if (itemNote.isNotEmpty) {
        await _bt.printCustom('   > $itemNote', 1, 1);
      }
    }

    if (note != null && note.isNotEmpty) {
      await _bt.printCustom('=' * w, 1, 1);
      await _bt.printCustom('Catatan: $note', 1, 1);
    }
    await _bt.printNewLine();
    await _bt.printNewLine();
    await _bt.printNewLine();
    await _bt.printNewLine();
  }

  /// Open cash drawer via ESC/POS pin 2 pulse command
  Future<void> openCashDrawer() async {
    if (!await _ensureConnected()) return;
    // ESC/POS: ESC p m t1 t2 — standard cash drawer command
    await _bt.printCustom('\x1Bp\x00\x19\x78', 1, 1);
  }

  // ──────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────

  Future<bool> _ensureConnected() async {
    try {
      final isConn = await _bt.isConnected;
      if (isConn == true) return true;
      // Try reconnect if we have a saved device
      if (state.connectedDevice != null) {
        await _bt.connect(state.connectedDevice!);
        state = state.copyWith(status: PrinterStatus.connected);
        return true;
      }
    } catch (_) {}
    state = state.copyWith(
      status: PrinterStatus.error,
      errorMessage: 'Printer tidak terhubung',
    );
    return false;
  }

  String _center(String s, int w) {
    if (s.length >= w) return s;
    final pad = (w - s.length) ~/ 2;
    return ' ' * pad + s;
  }

  String _rightAlign(String s, int w) =>
      s.length >= w ? s : s.padLeft(w);

  String _pair(String label, String value, int w) {
    final available = w - label.length - value.length;
    final spaces = available > 0 ? ' ' * available : ' ';
    return '$label$spaces$value';
  }

  String _fmtCurrency(int amount) {
    final s = amount.toString();
    final buf = StringBuffer('Rp');
    final chars = s.split('').reversed.toList();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write('.');
      buf.write(chars[i]);
    }
    return buf.toString().split('').reversed.join();
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

final bluetoothPrinterProvider =
    NotifierProvider<BluetoothPrinterNotifier, BluetoothPrinterState>(
  BluetoothPrinterNotifier.new,
);

final isPrinterConnectedProvider = Provider<bool>((ref) {
  return ref.watch(bluetoothPrinterProvider).isConnected;
});
