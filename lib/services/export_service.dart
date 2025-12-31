import 'dart:io' show File;
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/models/history_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportToPdf(List<Customer> customers) async {
    final pdf = pw.Document();

    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFF8F5), // Very light orange/cream
            ),
          ),
        );
      },
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'SR Ghani Business Report',
            style: pw.TextStyle(color: PdfColors.orange900, fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Customer Statement',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 12),
          ),
          pw.SizedBox(height: 30),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Mobile', 'Date', 'Status', 'Advance', 'Payment', 'Amount'],
            data: customers.map((c) => [
              c.name,
              c.mobileNumber ?? '-',
              DateFormat('dd/MM/yy').format(c.dateTime),
              c.status.replaceAll('_', ' ').toUpperCase(),
              c.isAdvancePaid == true ? 'YES (${c.advancePaymentMethod ?? '-'})' : 'NO',
              c.paymentMethod?.toUpperCase() ?? '-',
              c.extraCharge != null ? 'Rs.${c.extraCharge!.toStringAsFixed(0)}' : '-',
            ]).toList(),
            border: null,
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFF5722), // App primary color
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBE9E7)),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'customer_report.pdf');
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/customer_report.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'SR Ghani Data');
    }
  }

  static Future<void> exportToExcel(List<Customer> customers) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Mobile'),
      TextCellValue('Date'),
      TextCellValue('Status'),
      TextCellValue('Advance Paid'),
      TextCellValue('Advance Method'),
      TextCellValue('Final Payment'),
      TextCellValue('Amount (Paid)'),
    ]);

    for (var c in customers) {
      sheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.mobileNumber ?? '-'),
        TextCellValue(DateFormat('dd/MM/yy').format(c.dateTime)),
        TextCellValue(c.status),
        TextCellValue(c.isAdvancePaid == true ? 'YES' : 'NO'),
        TextCellValue(c.advancePaymentMethod ?? '-'),
        TextCellValue(c.paymentMethod?.toUpperCase() ?? '-'),
        DoubleCellValue(c.extraCharge ?? 0.0),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      if (kIsWeb) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              Uint8List.fromList(fileBytes),
              name: 'customer_data.xlsx',
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            )
          ],
          text: 'SR Ghani Data',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/customer_data.xlsx');
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'SR Ghani Data');
      }
    }
  }

  /// Optimised Scraper: Gets numbers from dashboard and history, 
  /// removes duplicates, and processes in background isolate.
  static Future<String?> scrapeAndDeduplicate(List<Customer> allCustomers) async {
    return await compute(_processNumbers, allCustomers);
  }

  static String _processNumbers(List<Customer> customers) {
    final numbers = customers
        .where((c) => c.mobileNumber != null && c.mobileNumber!.trim().isNotEmpty)
        .map((c) => _cleanNumber(c.mobileNumber!))
        .toSet(); // Automatically removes duplicates

    return numbers.join(', ');
  }

  static String _cleanNumber(String input) {
    // Basic cleaning: remove spaces, dashes, etc.
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static Future<void> saveNumbersToTextFile(String content) async {
    if (kIsWeb) {
      // For web, copying to clipboard is usually better, 
      // but we can also use printing to "save" if needed.
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/scraped_numbers.txt');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'SR Ghani Marketing Numbers');
    }
  }

  /// Exports a combined report of all historical and current data
  static Future<void> exportLifetimeReport(List<Customer> current, List<MonthlyHistory> history, {required bool isPdf}) async {
    final List<Customer> allData = [...current];
    for (var month in history) {
      allData.addAll(month.customers);
    }

    if (isPdf) {
      await exportToPdf(allData);
    } else {
      await exportToExcel(allData);
    }
  }

  /// Orchestrates the scraping and saving of mobile numbers from all data sources
  static Future<void> exportMobileNumbers(List<Customer> current, List<MonthlyHistory> history) async {
    final List<Customer> allData = [...current];
    for (var month in history) {
      allData.addAll(month.customers);
    }
    
    final content = await scrapeAndDeduplicate(allData);
    if (content != null && content.isNotEmpty) {
      await saveNumbersToTextFile(content);
    }
  }
}
