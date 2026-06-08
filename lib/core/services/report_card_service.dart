import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../shared/models/grade_record.dart';
import '../../shared/models/profile.dart';
import '../../shared/models/school.dart';
import '../../shared/models/school_class.dart';

class ReportCardService {
  Future<Uint8List> generateReportCard({
    required Profile student,
    required School? school,
    required SchoolClass? enrolledClass,
    required List<GradeRecord> grades,
    required double attendancePercentage,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  school?.name ?? 'School Report Card',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (school?.motto != null)
                  pw.Text(school!.motto!, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 16),
                pw.Text('Student: ${student.fullName}'),
                if (enrolledClass != null)
                  pw.Text('Class: ${enrolledClass.name}'),
                pw.Text(
                  'Attendance: ${attendancePercentage.toStringAsFixed(1)}%',
                ),
                pw.Text(
                  'Generated: ${DateTime.now().toIso8601String().split('T').first}',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Academic Results',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (grades.isEmpty)
            pw.Text('No grades recorded for this period.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Subject', 'Term', 'Score'],
              data: grades
                  .map(
                    (grade) => [
                      grade.subjectName ?? '—',
                      grade.termName ?? '—',
                      grade.score.toStringAsFixed(1),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );

    return doc.save();
  }
}
