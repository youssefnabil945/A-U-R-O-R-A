import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill/bill_model.dart';

class BillPdfService {
  /// Generate PDF for a bill
  Future<File> generatePdf(BillModel bill) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(bill),
          pw.SizedBox(height: 30),
          _buildBillInfo(bill),
          pw.SizedBox(height: 20),
          _buildRecipientInfo(bill),
          pw.SizedBox(height: 20),
          _buildItemsTable(bill),
          pw.SizedBox(height: 20),
          _buildTotals(bill),
          if (bill.notes != null && bill.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildNotes(bill),
          ],
          pw.SizedBox(height: 30),
          _buildFooter(bill),
        ],
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/bill_${bill.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Print bill directly
  Future<void> printBill(BillModel bill) async {
    final pdf = await generatePdf(bill);
    await Printing.layoutPdf(onLayout: (format) => pdf.readAsBytes());
  }

  /// Share bill as PDF
  Future<void> shareBill(BillModel bill) async {
    final pdf = await generatePdf(bill);
    await Printing.sharePdf(bytes: await pdf.readAsBytes(), filename: 'bill_${bill.id}.pdf');
  }

  pw.Widget _buildHeader(BillModel bill) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  bill.type.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Invoice #${bill.id.substring(0, 8).toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Date: ${_formatDate(bill.createdAt)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (bill.dueDate != null)
                  pw.Text(
                    'Due Date: ${_formatDate(bill.dueDate!)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBillInfo(BillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Status: ${bill.status.name.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _getStatusColor(bill.status),
                ),
              ),
            ],
          ),
          pw.Text(
            'Currency: ${bill.currency}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRecipientInfo(BillModel bill) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(bill.recipient.name, style: const pw.TextStyle(fontSize: 12)),
        if (bill.recipient.company != null)
          pw.Text(bill.recipient.company!, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(bill.recipient.email, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(bill.recipient.phone, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(bill.recipient.address, style: const pw.TextStyle(fontSize: 12)),
        if (bill.recipient.taxId != null)
          pw.Text('Tax ID: ${bill.recipient.taxId}', style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildItemsTable(BillModel bill) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      headerHeight: 30,
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headers: ['Description', 'Quantity', 'Unit Price', 'Amount'],
      data: bill.items.map((item) {
        return [
          item.description,
          item.quantity.toString(),
          '${bill.currency} ${item.price.toStringAsFixed(2)}',
          '${bill.currency} ${item.subtotal.toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTotals(BillModel bill) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                const pw.SizedBox(width: 150),
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text(
                  '${bill.currency} ${bill.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildNotes(BillModel bill) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(bill.notes!, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildFooter(BillModel bill) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated on ${DateTime.now().toString().substring(0, 19)}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  PdfColor _getStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return PdfColors.green700;
      case BillStatus.pending:
        return PdfColors.orange700;
      case BillStatus.overdue:
        return PdfColors.red700;
      case BillStatus.cancelled:
        return PdfColors.grey;
      case BillStatus.draft:
        return PdfColors.blueGrey;
    }
  }
}
