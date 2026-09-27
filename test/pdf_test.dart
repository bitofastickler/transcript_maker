import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcript_maker/main.dart';
import 'package:transcript_maker/transcript_calculator.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('PDF builds with accented names and a large course history', () async {
    final record = student(
      courses: [
        for (var i = 0; i < 80; i++)
          course('A', id: 'course-$i', credits: 0.25),
      ],
    ).copyWith(firstName: 'Alex José');
    final bytes = await TranscriptPdfService.build(
      student: record,
      snapshot: TranscriptCalculator(record).build(),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
    if (Platform.environment['WRITE_PDF_FIXTURE'] == '1') {
      await Directory('build/review').create(recursive: true);
      await File('build/review/sample-transcript.pdf').writeAsBytes(bytes);
    }
  });
}
