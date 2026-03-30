import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/client.dart';
import '../utils.dart';

class ExportService {
  Future<File> exportAllData({
    required List<Client> clients,
    required String currency,
    required String userName,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(excel, clients, currency, userName);
    _buildClientsSheet(excel, clients);
    _buildProjectsSheet(excel, clients, currency);
    _buildSessionsSheet(excel, clients);
    _buildFinancialSheet(excel, clients, currency);

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'FreelanceHub_Export_$timestamp.xlsx';
    final file = File('${dir.path}/$fileName');

    final bytes = excel.encode();
    if (bytes == null) {
      throw ExportException('Failed to encode workbook');
    }

    await file.writeAsBytes(bytes);
    return file;
  }

  void _buildSummarySheet(
    Excel excel,
    List<Client> clients,
    String currency,
    String userName,
  ) {
    final sheet = excel['Summary'];

    _writeCell(sheet, 0, 0, 'FreelanceHub - Data Export',
        bold: true, fontSize: 16);
    _writeCell(sheet, 1, 0, 'Exported by: $userName');
    _writeCell(sheet, 2, 0,
        'Export date: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}');
    _writeCell(sheet, 3, 0, 'Currency: $currency');

    sheet.appendRow([]);

    final allProjects = clients.expand((c) => c.projects).toList();
    final totalCollected = allProjects.fold(0.0, (s, p) => s + p.upfront);
    final totalOwed = allProjects.fold(0.0, (s, p) => s + p.remaining);
    final totalMrr = allProjects
        .where((p) => p.maintenanceActive)
        .fold(0.0, (s, p) => s + p.maintenanceFee);
    final totalProjects = allProjects.length;
    final activeProjects =
        allProjects.where((p) => p.status == 'active').length;
    final completedCount =
        allProjects.where((p) => p.status == 'completed').length;
    final totalMinutes = allProjects
        .expand((p) => p.sessions)
        .fold(0, (s, s2) => s + s2.durationMins);

    final summaryRows = [
      ['Metric', 'Value'],
      ['Total Clients', clients.length.toString()],
      ['Total Projects', totalProjects.toString()],
      ['Active Projects', activeProjects.toString()],
      ['Completed Projects', completedCount.toString()],
      ['Total Collected', fmtCurrency(totalCollected, currency)],
      ['Total Outstanding', fmtCurrency(totalOwed, currency)],
      ['Monthly Recurring (MRR)', fmtCurrency(totalMrr, currency)],
      [
        'Lifetime Value (est.)',
        fmtCurrency(totalCollected + totalOwed + totalMrr * 12, currency)
      ],
      ['Total Hours Logged', fmtDuration(totalMinutes)],
    ];

    for (var i = 0; i < summaryRows.length; i++) {
      final row = summaryRows[i];
      final isHeader = i == 0;
      _writeCell(
        sheet,
        5 + i,
        0,
        row[0],
        bold: isHeader,
        backgroundHex: isHeader ? 'FF202020' : null,
        fontColorHex: isHeader ? 'FFFFFFFF' : null,
      );
      _writeCell(
        sheet,
        5 + i,
        1,
        row[1],
        bold: isHeader,
        backgroundHex: isHeader ? 'FF202020' : null,
        fontColorHex: isHeader ? 'FFFFFFFF' : null,
      );
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 25);
  }

  void _buildClientsSheet(Excel excel, List<Client> clients) {
    final sheet = excel['Clients'];

    final headers = [
      'Name',
      'Company',
      'Category',
      'Email',
      'Phone',
      'Projects',
      'Active',
      'Member Since',
      'Notes',
    ];
    _writeHeaderRow(sheet, headers);

    for (final c in clients) {
      sheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.company),
        TextCellValue(c.primaryCategory),
        TextCellValue(c.email),
        TextCellValue(c.phone),
        IntCellValue(c.projects.length),
        IntCellValue(c.activeCount),
        TextCellValue(c.createdAt),
        TextCellValue(c.notes),
      ]);
    }

    _setColumnWidths(sheet, [22, 20, 16, 28, 18, 10, 8, 14, 40]);
  }

  void _buildProjectsSheet(Excel excel, List<Client> clients, String currency) {
    final sheet = excel['Projects'];

    final headers = [
      'Client',
      'Project Name',
      'Category',
      'Status',
      'Pricing',
      'Total Value',
      'Upfront Paid',
      'Remaining',
      'Maintenance/mo',
      'Maintenance Active',
      'Est. Hours',
      'Logged Hours',
      'Progress %',
      'Start Date',
      'Deadline',
      'Days Left',
      'Services',
      'Notes',
    ];
    _writeHeaderRow(sheet, headers);

    for (final c in clients) {
      for (final p in c.projects) {
        final days = daysLeft(p.deadline);
        final progress = p.estimatedHours > 0
            ? '${(p.loggedHours / p.estimatedHours * 100).round().clamp(0, 100)}%'
            : '0%';
        final daysLeftStr =
            days < 0 ? 'Overdue by ${days.abs()} days' : '$days days';

        sheet.appendRow([
          TextCellValue(c.name),
          TextCellValue(p.name),
          TextCellValue(p.category),
          TextCellValue(_statusLabel(p.status)),
          TextCellValue(p.pricingType == 'fixed' ? 'Fixed Price' : 'Hourly'),
          TextCellValue(fmtCurrency(p.upfront + p.remaining, currency)),
          TextCellValue(fmtCurrency(p.upfront, currency)),
          TextCellValue(fmtCurrency(p.remaining, currency)),
          TextCellValue(p.maintenanceFee > 0
              ? fmtCurrency(p.maintenanceFee, currency)
              : '-'),
          TextCellValue(p.maintenanceActive ? 'Yes' : 'No'),
          DoubleCellValue(p.estimatedHours),
          DoubleCellValue(double.parse(p.loggedHours.toStringAsFixed(2))),
          TextCellValue(progress),
          TextCellValue(p.startDate),
          TextCellValue(p.deadline),
          TextCellValue(daysLeftStr),
          TextCellValue(p.services.join(', ')),
          TextCellValue(p.notes),
        ]);
      }
    }

    _setColumnWidths(
      sheet,
      [20, 24, 16, 12, 10, 14, 14, 14, 14, 10, 10, 12, 10, 12, 12, 16, 30, 36],
    );
  }

  void _buildSessionsSheet(Excel excel, List<Client> clients) {
    final sheet = excel['Work Sessions'];

    final headers = [
      'Client',
      'Project',
      'Date',
      'Duration (min)',
      'Duration (h)',
      'Note'
    ];
    _writeHeaderRow(sheet, headers);

    for (final c in clients) {
      for (final p in c.projects) {
        final sorted = List.of(p.sessions)
          ..sort((a, b) => a.date.compareTo(b.date));

        for (final s in sorted) {
          sheet.appendRow([
            TextCellValue(c.name),
            TextCellValue(p.name),
            TextCellValue(s.date),
            IntCellValue(s.durationMins),
            TextCellValue(fmtDuration(s.durationMins)),
            TextCellValue(s.note),
          ]);
        }
      }
    }

    _setColumnWidths(sheet, [20, 24, 14, 14, 12, 40]);
  }

  void _buildFinancialSheet(
      Excel excel, List<Client> clients, String currency) {
    final sheet = excel['Financial'];

    _writeCell(sheet, 0, 0, 'Per-Client Financial Breakdown',
        bold: true, fontSize: 13);
    sheet.appendRow([]);

    final clientHeaders = [
      'Client',
      'Total Value',
      'Collected',
      'Outstanding',
      'MRR',
      'Projects'
    ];
    _writeHeaderRow(sheet, clientHeaders, startRow: 2);

    var row = 3;
    for (final c in clients) {
      final totalVal =
          c.projects.fold(0.0, (s, p) => s + p.upfront + p.remaining);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(c.name);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(fmtCurrency(totalVal, currency));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(fmtCurrency(c.totalPaid, currency));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(fmtCurrency(c.totalOwed, currency));
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value =
          TextCellValue(
              c.totalMrr > 0 ? '${fmtCurrency(c.totalMrr, currency)}/mo' : '-');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = IntCellValue(c.projects.length);
      row++;
    }

    final grandTotal =
        clients.fold(0.0, (s, c) => s + c.totalPaid + c.totalOwed);
    final grandPaid = clients.fold(0.0, (s, c) => s + c.totalPaid);
    final grandOwed = clients.fold(0.0, (s, c) => s + c.totalOwed);
    final grandMrr = clients.fold(0.0, (s, c) => s + c.totalMrr);

    _writeCell(sheet, row, 0, 'TOTAL', bold: true, backgroundHex: 'FFc9f158');
    _writeCell(
      sheet,
      row,
      1,
      fmtCurrency(grandTotal, currency),
      bold: true,
      backgroundHex: 'FFc9f158',
    );
    _writeCell(
      sheet,
      row,
      2,
      fmtCurrency(grandPaid, currency),
      bold: true,
      backgroundHex: 'FFc9f158',
    );
    _writeCell(
      sheet,
      row,
      3,
      fmtCurrency(grandOwed, currency),
      bold: true,
      backgroundHex: 'FFc9f158',
    );
    _writeCell(
      sheet,
      row,
      4,
      '${fmtCurrency(grandMrr, currency)}/mo',
      bold: true,
      backgroundHex: 'FFc9f158',
    );
    _writeCell(
      sheet,
      row,
      5,
      clients.length.toString(),
      bold: true,
      backgroundHex: 'FFc9f158',
    );

    _setColumnWidths(sheet, [22, 16, 16, 16, 14, 10]);
  }

  void _writeHeaderRow(Sheet sheet, List<String> headers, {int startRow = 0}) {
    final rowIdx = startRow == 0 ? sheet.maxRows : startRow;
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF202020'),
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        fontSize: 11,
      );
    }
  }

  void _writeCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    int? fontSize,
    String? backgroundHex,
    String? fontColorHex,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    if (backgroundHex != null && fontColorHex != null) {
      cell.cellStyle = CellStyle(
        bold: bold,
        fontSize: fontSize,
        backgroundColorHex: ExcelColor.fromHexString(backgroundHex),
        fontColorHex: ExcelColor.fromHexString(fontColorHex),
      );
      return;
    }
    if (backgroundHex != null) {
      cell.cellStyle = CellStyle(
        bold: bold,
        fontSize: fontSize,
        backgroundColorHex: ExcelColor.fromHexString(backgroundHex),
      );
      return;
    }
    if (fontColorHex != null) {
      cell.cellStyle = CellStyle(
        bold: bold,
        fontSize: fontSize,
        fontColorHex: ExcelColor.fromHexString(fontColorHex),
      );
      return;
    }
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize,
    );
  }

  void _setColumnWidths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  String _statusLabel(String status) => switch (status) {
        'active' => 'Active',
        'completed' => 'Completed',
        'paused' => 'Paused',
        'cancelled' => 'Cancelled',
        _ => status,
      };
}

class ExportException implements Exception {
  ExportException(this.message);

  final String message;

  @override
  String toString() => 'ExportException: $message';
}
