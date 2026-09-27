import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcript_maker/main.dart';
import 'package:transcript_maker/local_store.dart';
import 'fixtures.dart';

void main() {
  testWidgets(
    'starts without accounts or configuration and explains local files',
    (tester) async {
      await tester.pumpWidget(const HomeschoolLedgerApp());
      await tester.pumpAndSettle();
      expect(find.text('Transcript Maker'), findsOneWidget);
      expect(find.text('Add Student'), findsOneWidget);
      expect(find.byTooltip('Open transcript file'), findsOneWidget);
      expect(find.textContaining('Local files only'), findsOneWidget);
      expect(find.textContaining('Sign in'), findsNothing);
    },
  );
  testWidgets(
    'student edits stay local, failed save preserves edits, route exit asks',
    (tester) async {
      var updates = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StudentDetailPage(
            student: student(),
            onStudentUpdated: (_) {
              updates++;
            },
            onStudentDeleted: (_) async {},
            onSaveStudent: (_) async => throw SaveCancelled(),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Edit student'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Edited',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(updates, 0);
      await tester.tap(find.text('Save file'));
      await tester.pumpAndSettle();
      expect(updates, 0);
      expect(find.textContaining('Save cancelled'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard student edits?'), findsOneWidget);
    },
  );
  testWidgets('student view fits a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: StudentDetailPage(
          student: student(courses: [course('A')]),
          onStudentUpdated: (_) {},
          onStudentDeleted: (_) async {},
          onSaveStudent: (record) async => record,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Add Class'), findsOneWidget);
  });
}
