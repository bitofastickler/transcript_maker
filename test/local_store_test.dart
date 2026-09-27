import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcript_maker/local_store.dart';
import 'fixtures.dart';

void main() {
  test('file round trip retains all student and child data and IDs', () {
    final original = student(courses: [course('A', credits: 0.25)]);
    expect(
      TranscriptFile.decode(TranscriptFile.encode([original])).single.toMap(),
      original.toMap(),
    );
  });
  test(
    'rejects future versions, unknown grades, duplicate IDs and foreign children',
    () {
      final base = jsonDecode(
        utf8.decode(
          TranscriptFile.encode([
            student(courses: [course('A')]),
          ]),
        ),
      );
      Uint8List bytes(dynamic data) =>
          Uint8List.fromList(utf8.encode(jsonEncode(data)));
      for (final change in <void Function(dynamic)>[
        (d) => d['version'] = 999,
        (d) => d['students'][0]['enrollments'][0]['grade_letter'] = 'banana',
        (d) => d['students'].add(d['students'][0]),
        (d) =>
            d['students'][0]['enrollments'][0]['student_id'] = 'someone-else',
        (d) => d['students'][0]['enrollments'][0]['credit_hours'] = -1,
        (d) => d['students'][0]['enrollments'] = [null],
        (d) => d['students'][0]['date_of_birth'] = '2010-02-31',
      ]) {
        final data = jsonDecode(jsonEncode(base));
        change(data);
        expect(() => TranscriptFile.decode(bytes(data)), throwsFormatException);
      }
    },
  );
  test(
    'malformed and oversized files are rejected without replacing current work',
    () async {
      final store = LocalStudentStore();
      await store.createStudent(student());
      expect(
        () => store.importBytes(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
      expect(
        () => store.importBytes(Uint8List(TranscriptFile.maxBytes + 1)),
        throwsFormatException,
      );
      expect((await store.fetchStudents()).single.firstName, 'Alex');
      expect(store.hasUnsavedChanges, isTrue);
    },
  );
  test(
    'cancelled and failed saves preserve prior committed data and dirty state',
    () async {
      for (final saver in <SaveBytes>[
        (bytes) async => false,
        (bytes) async => throw StateError('disk full'),
      ]) {
        final store = LocalStudentStore(saveBytes: saver);
        await store.createStudent(student());
        await expectLater(
          store.saveStudent(student().copyWith(firstName: 'Changed')),
          throwsA(anyOf(isA<Exception>(), isA<Error>())),
        );
        expect((await store.fetchStudents()).single.firstName, 'Alex');
        expect(store.hasUnsavedChanges, isTrue);
      }
    },
  );
  test(
    'saving a student writes every student and commits only after success',
    () async {
      Uint8List? saved;
      final store = LocalStudentStore(
        saveBytes: (bytes) async {
          saved = bytes;
          return true;
        },
      );
      await store.createStudent(student());
      await store.saveStudent(student().copyWith(firstName: 'Changed'));
      expect(TranscriptFile.decode(saved!).single.firstName, 'Changed');
      expect(store.hasUnsavedChanges, isFalse);
    },
  );
}
