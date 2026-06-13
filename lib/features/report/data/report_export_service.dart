import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';

/// Report data model for export
class ReportData {
  final String period;
  final DateTime from;
  final DateTime to;
  final int totalSales;
  final int totalTransactions;
  final int totalRefunds;
  final int totalCancels;
  final List<ReportOrderRow> orders;
  final List<ReportProductRow> topProducts;

  const ReportData({
    required this.period,
    required this.from,
    required this.to,
    required this.totalSales,
    required this.totalTransactions,
    required this.totalRefunds,
    required this.totalCancels,
    required this.orders,
    required this.topProducts,
  });
}

class ReportOrderRow {
  final String orderNumber;
  final DateTime date;
  final String cashierName;
  final String paymentMethod;
  final int total;
  final String status;

  const ReportOrderRow({
    required this.orderNumber,
    required this.date,
    required this.cashierName,
    required this.paymentMethod,
    required this.total,
    required this.status,
  });
}

class ReportProductRow {
  final String productName;
  final String category;
  final int qty;
  final int revenue;

  const ReportProductRow({
    required this.productName,
    required this.category,
    required this.qty,
    required this.revenue,
  });
}

class ReportExportService {
  static final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  // ──────────────────────────────────────────
  // PDF Export
  // ──────────────────────────────────────────
  static Future<String> exportPdf(ReportData data) async {
    final pdf = pw.Document();

    // Load font
    pw.Font? boldFont;
    pw.Font? regularFont;
    try {
      final boldData = await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf');
      final regularData = await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf');
      boldFont = pw.Font.ttf(boldData);
      regularFont = pw.Font.ttf(regularData);
    } catch (_) {
      // Fallback to default fonts
    }

    final bold = pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold);
    final regular = pw.TextStyle(font: regularFont);
    final gold = PdfColor.fromHex('#B89047');
    final charcoal = PdfColor.fromHex('#1A1B1E');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BobKasir',
                      style: bold.copyWith(fontSize: 20, color: charcoal)),
                  pw.Text('Laporan Penjualan',
                      style: regular.copyWith(
                          fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(data.period, style: bold.copyWith(fontSize: 14)),
                  pw.Text(
                    '${_dateFmt.format(data.from)} - ${_dateFmt.format(data.to)}',
                    style: regular.copyWith(
                        fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Summary cards
          pw.Row(children: [
            _pdfSummaryBox('Total Penjualan', _currencyFmt.format(data.totalSales), gold, bold, regular),
            pw.SizedBox(width: 12),
            _pdfSummaryBox('Transaksi', '${data.totalTransactions}', charcoal, bold, regular),
            pw.SizedBox(width: 12),
            _pdfSummaryBox('Refund', '${data.totalRefunds}', PdfColor.fromHex('#C62828'), bold, regular),
            pw.SizedBox(width: 12),
            _pdfSummaryBox('Cancel', '${data.totalCancels}', PdfColor.fromHex('#D89A29'), bold, regular),
          ]),
          pw.SizedBox(height: 24),

          // Orders table
          pw.Text('Detail Transaksi', style: bold.copyWith(fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                children: ['No. Order', 'Tanggal', 'Kasir', 'Metode', 'Total', 'Status']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h, style: bold.copyWith(fontSize: 8)),
                        ))
                    .toList(),
              ),
              // Rows
              ...data.orders.map(
                (o) => pw.TableRow(
                  children: [
                    o.orderNumber,
                    _dateFmt.format(o.date),
                    o.cashierName,
                    o.paymentMethod,
                    _currencyFmt.format(o.total),
                    o.status,
                  ]
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(cell,
                                style: regular.copyWith(fontSize: 8)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // Top products
          if (data.topProducts.isNotEmpty) ...[
            pw.Text('Produk Terlaris', style: bold.copyWith(fontSize: 14)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                  children: ['Produk', 'Kategori', 'Qty', 'Revenue']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h, style: bold.copyWith(fontSize: 8)),
                          ))
                      .toList(),
                ),
                ...data.topProducts.map(
                  (p) => pw.TableRow(
                    children: [
                      p.productName,
                      p.category,
                      '${p.qty}',
                      _currencyFmt.format(p.revenue),
                    ]
                        .map((cell) => pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(cell,
                                  style: regular.copyWith(fontSize: 8)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],

          // Footer
          pw.SizedBox(height: 32),
          pw.Divider(color: PdfColors.grey300),
          pw.Center(
            child: pw.Text(
              'Created by StarCyberCompany · BobKasir',
              style: regular.copyWith(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    // Save to file
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'BobKasir_Laporan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _pdfSummaryBox(
    String label,
    String value,
    PdfColor color,
    pw.TextStyle bold,
    pw.TextStyle regular,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: regular.copyWith(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: bold.copyWith(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Excel Export
  // ──────────────────────────────────────────
  static Future<String> exportExcel(ReportData data) async {
    final excel = Excel.createExcel();

    // ── Sheet 1: Summary ──
    final summarySheet = excel['Ringkasan'];
    summarySheet.appendRow([
      TextCellValue('BobKasir — Laporan Penjualan'),
    ]);
    summarySheet.appendRow([TextCellValue('Periode: ${data.period}')]);
    summarySheet.appendRow([
      TextCellValue(
          '${_dateFmt.format(data.from)} s/d ${_dateFmt.format(data.to)}'),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Total Penjualan'),
      IntCellValue(data.totalSales),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Transaksi'),
      IntCellValue(data.totalTransactions),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Refund'),
      IntCellValue(data.totalRefunds),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Cancel'),
      IntCellValue(data.totalCancels),
    ]);

    // ── Sheet 2: Transaksi ──
    final txSheet = excel['Transaksi'];
    txSheet.appendRow([
      TextCellValue('No. Order'),
      TextCellValue('Tanggal'),
      TextCellValue('Kasir'),
      TextCellValue('Metode'),
      TextCellValue('Total'),
      TextCellValue('Status'),
    ]);
    for (final o in data.orders) {
      txSheet.appendRow([
        TextCellValue(o.orderNumber),
        TextCellValue(_dateFmt.format(o.date)),
        TextCellValue(o.cashierName),
        TextCellValue(o.paymentMethod),
        IntCellValue(o.total),
        TextCellValue(o.status),
      ]);
    }

    // ── Sheet 3: Produk ──
    if (data.topProducts.isNotEmpty) {
      final prodSheet = excel['Produk Terlaris'];
      prodSheet.appendRow([
        TextCellValue('Produk'),
        TextCellValue('Kategori'),
        TextCellValue('Qty Terjual'),
        TextCellValue('Revenue'),
      ]);
      for (final p in data.topProducts) {
        prodSheet.appendRow([
          TextCellValue(p.productName),
          TextCellValue(p.category),
          IntCellValue(p.qty),
          IntCellValue(p.revenue),
        ]);
      }
    }

    // Remove default sheet
    excel.delete('Sheet1');

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'BobKasir_Laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final path = '${dir.path}/$filename';
    final bytes = excel.save();
    if (bytes != null) {
      await File(path).writeAsBytes(bytes);
    }
    return path;
  }

  /// Open file with system viewer
  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  // ── Sample data for testing ──
  static ReportData sampleReport() {
    final now = DateTime.now();
    return ReportData(
      period: 'Harian',
      from: DateTime(now.year, now.month, now.day),
      to: now,
      totalSales: 1250000,
      totalTransactions: 23,
      totalRefunds: 1,
      totalCancels: 2,
      orders: [
        ReportOrderRow(
          orderNumber: 'BK-20260610-0001',
          date: now.subtract(const Duration(hours: 2)),
          cashierName: 'Admin',
          paymentMethod: 'Cash',
          total: 118000,
          status: 'Selesai',
        ),
        ReportOrderRow(
          orderNumber: 'BK-20260610-0002',
          date: now.subtract(const Duration(hours: 4)),
          cashierName: 'Sari',
          paymentMethod: 'QRIS',
          total: 57000,
          status: 'Selesai',
        ),
      ],
      topProducts: [
        ReportProductRow(productName: 'Latte', category: 'Minuman', qty: 42, revenue: 42 * 32000),
        ReportProductRow(productName: 'Americano', category: 'Minuman', qty: 38, revenue: 38 * 25000),
        ReportProductRow(productName: 'Cappuccino', category: 'Minuman', qty: 25, revenue: 25 * 30000),
      ],
    );
  }
}
