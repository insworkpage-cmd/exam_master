import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class ExportService {
  // خروجی گرفتن از داده‌ها به صورت Excel
  static Future<void> exportToExcel({
    required List<Map<String, dynamic>> data,
    required String fileName,
    required List<String> headers,
    String? sheetName,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[sheetName ?? 'Sheet1'];
      // افزودن هدرها
      sheet.appendRow(headers);
      // افزودن داده‌ها
      for (var row in data) {
        final List<dynamic> rowData = [];
        for (var header in headers) {
          rowData.add(row[header] ?? '');
        }
        sheet.appendRow(rowData);
      }
      // ذخیره فایل
      final directory = await getApplicationDocumentsDirectory();
      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final file = File('${directory.path}/$safeFileName.xlsx');

      // اصلاح: بررسی null بودن نتیجه encode
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      } else {
        throw Exception('Failed to encode Excel file');
      }

      Logger.info('Excel file exported to: ${file.path}');
    } catch (e) {
      Logger.error('Error exporting to Excel: $e');
      rethrow;
    }
  }

  // خروجی گرفتن از داده‌ها به صورت CSV
  static Future<void> exportToCSV({
    required List<Map<String, dynamic>> data,
    required String fileName,
    required List<String> headers,
  }) async {
    try {
      final buffer = StringBuffer();
      // افزودن هدرها
      buffer.writeln(headers.join(','));
      // افزودن داده‌ها
      for (var row in data) {
        final List<String> rowData = [];
        for (var header in headers) {
          var value = row[header]?.toString() ?? '';
          // فرار از کاراکترهای خاص در CSV
          if (value.contains(',') ||
              value.contains('"') ||
              value.contains('\n')) {
            value = '"${value.replaceAll('"', '""')}"';
          }
          rowData.add(value);
        }
        buffer.writeln(rowData.join(','));
      }
      // ذخیره فایل
      final directory = await getApplicationDocumentsDirectory();
      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final file = File('${directory.path}/$safeFileName.csv');
      await file.writeAsString(buffer.toString());
      Logger.info('CSV file exported to: ${file.path}');
    } catch (e) {
      Logger.error('Error exporting to CSV: $e');
      rethrow;
    }
  }

  // خروجی گرفتن از داده‌ها به صورت PDF
  static Future<void> exportToPDF({
    required List<Map<String, dynamic>> data,
    required String fileName,
    required String title,
    required List<String> headers,
    String? subtitle,
    pw.Widget? headerWidget,
    pw.Widget? footerWidget,
  }) async {
    try {
      final pdf = pw.Document();
      // افزودن فونت فارسی
      final font = await _loadPersianFont();
      // افزودن صفحه
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              children: [
                // هدر
                if (headerWidget != null)
                  headerWidget
                else
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
                pw.SizedBox(height: 20),
                // جدول داده‌ها
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: data.map((row) {
                    return headers
                        .map((header) => row[header]?.toString() ?? '')
                        .toList();
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  cellStyle: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                  ),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.indigo),
                  cellAlignment: pw.Alignment.centerRight,
                  cellPadding: const pw.EdgeInsets.all(5),
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                ),
                pw.SizedBox(height: 20),
                // فوتر
                if (footerWidget != null)
                  footerWidget
                else
                  pw.Text(
                    'تاریخ تولید: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      // ذخیره یا نمایش فایل
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
      Logger.info('PDF file exported: $fileName');
    } catch (e) {
      Logger.error('Error exporting to PDF: $e');
      rethrow;
    }
  }

  // خروجی گرفتن گزارش کاربران
  static Future<void> exportUserReport({
    required List<Map<String, dynamic>> users,
    required String fileName,
    ExportFormat format = ExportFormat.excel,
  }) async {
    final headers = [
      'شناسه کاربر',
      'نام',
      'ایمیل',
      'نقش',
      'وضعیت',
      'تاریخ ایجاد',
      'آخرین ورود',
    ];
    final data = users.map((user) {
      return {
        'شناسه کاربر': user['uid'] ?? '',
        'نام': user['name'] ?? '',
        'ایمیل': user['email'] ?? '',
        'نقش': user['role'] ?? '',
        'وضعیت': user['isActive'] == true ? 'فعال' : 'غیرفعال',
        'تاریخ ایجاد': _formatDateTime(user['createdAt']),
        'آخرین ورود': _formatDateTime(user['lastLogin']),
      };
    }).toList();
    switch (format) {
      case ExportFormat.excel:
        await exportToExcel(
          data: data,
          fileName: fileName,
          headers: headers,
          sheetName: 'کاربران',
        );
        break;
      case ExportFormat.csv:
        await exportToCSV(
          data: data,
          fileName: fileName,
          headers: headers,
        );
        break;
      case ExportFormat.pdf:
        await exportToPDF(
          data: data,
          fileName: fileName,
          title: 'گزارش کاربران',
          headers: headers,
          subtitle: 'لیست تمام کاربران سیستم',
        );
        break;
    }
  }

  // خروجی گرفتن گزارش آزمون‌ها
  static Future<void> exportQuizReport({
    required List<Map<String, dynamic>> quizzes,
    required String fileName,
    ExportFormat format = ExportFormat.excel,
  }) async {
    final headers = [
      'عنوان آزمون',
      'تعداد سوالات',
      'میانگین نمره',
      'تعداد شرکت‌کنندگان',
      'نرخ تکمیل',
      'تاریخ ایجاد',
    ];
    final data = quizzes.map((quiz) {
      return {
        'عنوان آزمون': quiz['title'] ?? '',
        'تعداد سوالات': quiz['questionCount'] ?? 0,
        'میانگین نمره': quiz['averageScore']?.toString() ?? '0',
        'تعداد شرکت‌کنندگان': quiz['participants'] ?? 0,
        'نرخ تکمیل': '${quiz['completionRate'] ?? 0}%',
        'تاریخ ایجاد': _formatDateTime(quiz['createdAt']),
      };
    }).toList();
    switch (format) {
      case ExportFormat.excel:
        await exportToExcel(
          data: data,
          fileName: fileName,
          headers: headers,
          sheetName: 'آزمون‌ها',
        );
        break;
      case ExportFormat.csv:
        await exportToCSV(
          data: data,
          fileName: fileName,
          headers: headers,
        );
        break;
      case ExportFormat.pdf:
        await exportToPDF(
          data: data,
          fileName: fileName,
          title: 'گزارش آزمون‌ها',
          headers: headers,
          subtitle: 'لیست تمام آزمون‌های سیستم',
        );
        break;
    }
  }

  // خروجی گرفتن گزارش سوالات
  static Future<void> exportQuestionReport({
    required List<Map<String, dynamic>> questions,
    required String fileName,
    ExportFormat format = ExportFormat.excel,
  }) async {
    final headers = [
      'متن سوال',
      'دسته‌بندی',
      'سطح دشواری',
      'وضعیت',
      'مدرس',
      'تاریخ ایجاد',
    ];
    final data = questions.map((question) {
      return {
        'متن سوال': question['text'] ?? '',
        'دسته‌بندی': question['category'] ?? '',
        'سطح دشواری': question['difficulty'] ?? '',
        'وضعیت': _getQuestionStatusText(question['status']),
        'مدرس': question['instructorName'] ?? '',
        'تاریخ ایجاد': _formatDateTime(question['createdAt']),
      };
    }).toList();
    switch (format) {
      case ExportFormat.excel:
        await exportToExcel(
          data: data,
          fileName: fileName,
          headers: headers,
          sheetName: 'سوالات',
        );
        break;
      case ExportFormat.csv:
        await exportToCSV(
          data: data,
          fileName: fileName,
          headers: headers,
        );
        break;
      case ExportFormat.pdf:
        await exportToPDF(
          data: data,
          fileName: fileName,
          title: 'گزارش سوالات',
          headers: headers,
          subtitle: 'لیست تمام سوالات سیستم',
        );
        break;
    }
  }

  // خروجی گرفتن گزارش فعالیت‌ها
  static Future<void> exportActivityReport({
    required List<Map<String, dynamic>> activities,
    required String fileName,
    ExportFormat format = ExportFormat.excel,
  }) async {
    final headers = [
      'کاربر',
      'نوع فعالیت',
      'توضیحات',
      'تاریخ و زمان',
    ];
    final data = activities.map((activity) {
      return {
        'کاربر': activity['userName'] ?? '',
        'نوع فعالیت': activity['type'] ?? '',
        'توضیحات': activity['description'] ?? '',
        'تاریخ و زمان': _formatDateTime(activity['timestamp']),
      };
    }).toList();
    switch (format) {
      case ExportFormat.excel:
        await exportToExcel(
          data: data,
          fileName: fileName,
          headers: headers,
          sheetName: 'فعالیت‌ها',
        );
        break;
      case ExportFormat.csv:
        await exportToCSV(
          data: data,
          fileName: fileName,
          headers: headers,
        );
        break;
      case ExportFormat.pdf:
        await exportToPDF(
          data: data,
          fileName: fileName,
          title: 'گزارش فعالیت‌ها',
          headers: headers,
          subtitle: 'لاگ فعالیت‌های سیستم',
        );
        break;
    }
  }

  // خروجی گرفتن گزارش تحلیلی
  static Future<void> exportAnalyticsReport({
    required Map<String, dynamic> analytics,
    required String fileName,
    ExportFormat format = ExportFormat.pdf,
  }) async {
    final pdf = pw.Document();
    final font = await _loadPersianFont();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Text(
                'گزارش تحلیلی سیستم',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'تاریخ تولید: ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
              pw.SizedBox(height: 30),
              // بخش آمار کاربران
              _buildAnalyticsSection(
                font,
                'آمار کاربران',
                analytics['userGrowth'],
              ),
              pw.SizedBox(height: 20),
              // بخش عملکرد آزمون‌ها
              _buildAnalyticsSection(
                font,
                'عملکرد آزمون‌ها',
                analytics['quizPerformance'],
              ),
              pw.SizedBox(height: 20),
              // بخش آمار سوالات
              _buildAnalyticsSection(
                font,
                'آمار سوالات',
                analytics['questionStats'],
              ),
              pw.SizedBox(height: 20),
              // بخش فعالیت‌ها
              _buildAnalyticsSection(
                font,
                'فعالیت‌های سیستم',
                analytics['activityTrends'],
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  // ساخت بخش تحلیلی در PDF
  static pw.Widget _buildAnalyticsSection(
    pw.Font font,
    String title,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: data.entries.map((entry) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    entry.key,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    entry.value.toString(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // متدهای کمکی
  static Future<pw.Font> _loadPersianFont() async {
    // در اینجا باید فونت فارسی را لود کنید
    // فعلاً از فونت پیش‌فرض استفاده می‌کنیم
    return pw.Font.ttf(
        await rootBundle.load('lib/assets/fonts/Vazirmatn-Regular.ttf'));
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return DateFormat('yyyy/MM/dd HH:mm').format(date);
    }
    // بررسی نوع داده برای Timestamp
    if (date is Map && date['_seconds'] != null) {
      // اگر از Firebase Timestamp استفاده می‌کنید
      try {
        final seconds = date['_seconds'] as int;
        final nanos = date['_nanoseconds'] as int;
        return DateFormat('yyyy/MM/dd HH:mm').format(
            DateTime.fromMillisecondsSinceEpoch(
                seconds * 1000 + nanos ~/ 1000000));
      } catch (e) {
        return date.toString();
      }
    }
    return date.toString();
  }

  static String _formatDateTime(dynamic dateTime) {
    return _formatDate(dateTime);
  }

  static String _getQuestionStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'در انتظار تأیید';
      case 'approved':
        return 'تأیید شده';
      case 'rejected':
        return 'رد شده';
      default:
        return status ?? 'نامشخص';
    }
  }
}

// انواع فرمت خروجی
enum ExportFormat {
  excel,
  csv,
  pdf,
}

// کلاس کمکی برای مدیریت عملیات خروجی
class ExportHelper {
  static Future<void> showExportDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    String? defaultFileName,
    List<ExportFormat> availableFormats = const [
      ExportFormat.excel,
      ExportFormat.csv,
      ExportFormat.pdf,
    ],
  }) async {
    final fileNameController = TextEditingController(
      text: defaultFileName ?? _generateFileName(title),
    );
    ExportFormat selectedFormat = availableFormats.first;

    // ذخیره ScaffoldMessenger برای استفاده در آینده
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('خروجی گرفتن $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fileNameController,
                  decoration: const InputDecoration(
                    labelText: 'نام فایل',
                    hintText: 'نام فایل را وارد کنید',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExportFormat>(
                  value: selectedFormat,
                  decoration: const InputDecoration(
                    labelText: 'فرمت خروجی',
                  ),
                  items: availableFormats.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(_getFormatText(format)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFormat = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    // استفاده از متد مناسب برای فرمت انتخاب شده
                    switch (selectedFormat) {
                      case ExportFormat.excel:
                        await ExportService.exportToExcel(
                          data: data,
                          fileName: fileNameController.text,
                          headers: headers,
                        );
                        break;
                      case ExportFormat.csv:
                        await ExportService.exportToCSV(
                          data: data,
                          fileName: fileNameController.text,
                          headers: headers,
                        );
                        break;
                      case ExportFormat.pdf:
                        await ExportService.exportToPDF(
                          data: data,
                          fileName: fileNameController.text,
                          title: title,
                          headers: headers,
                        );
                        break;
                    }

                    // استفاده از scaffoldMessenger ذخیره شده
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('فایل با موفقیت خروجی گرفته شد'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // استفاده از scaffoldMessenger ذخیره شده
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('خطا در خروجی گرفتن: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('خروجی'),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _generateFileName(String title) {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(now);
    return '${title}_$formattedDate';
  }

  static String _getFormatText(ExportFormat format) {
    switch (format) {
      case ExportFormat.excel:
        return 'Excel (.xlsx)';
      case ExportFormat.csv:
        return 'CSV (.csv)';
      case ExportFormat.pdf:
        return 'PDF (.pdf)';
    }
  }
}
