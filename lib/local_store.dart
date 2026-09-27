import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'models/student.dart';
import 'platform/unsaved.dart';

/// The only persistence boundary. No network, accounts, or browser storage.
class TranscriptFile {
  static const maxBytes = 10 * 1024 * 1024;
  static Uint8List encode(List<StudentRecord> students) => Uint8List.fromList(
    utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'format': 'transcript-maker',
        'version': 1,
        'students': students.map((student) => student.toMap()).toList(),
      }),
    ),
  );

  static List<StudentRecord> decode(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('File exceeds 10 MB.');
    }
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map<String, dynamic> ||
        data['format'] != 'transcript-maker' ||
        data['version'] != 1) {
      throw const FormatException(
        'Unsupported transcript file format or version.',
      );
    }
    final rows = data['students'];
    if (rows is! List || rows.length > 500) {
      throw const FormatException('Invalid student list.');
    }
    final ids = <String>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Invalid student.');
      }
      for (final field in ['id', 'first_name', 'last_name', 'date_of_birth']) {
        _text(row, field, required: true);
      }
      if (!ids.add(row['id'] as String)) {
        throw const FormatException('Duplicate student ID.');
      }
      final dob = row['date_of_birth'] as String;
      final date = DateTime.tryParse(dob);
      if (date == null ||
          dob.length < 10 ||
          date.toIso8601String().substring(0, 10) != dob.substring(0, 10)) {
        throw const FormatException('Invalid birth date.');
      }
      _integer(row, 'target_grad_year', 1900, 2200);
      for (final field in ['email', 'phone', 'address', 'notes']) {
        _text(row, field);
      }
      for (final kind in ['enrollments', 'awards', 'activities']) {
        final children = row[kind];
        if (children is! List || children.length > 2000) {
          throw const FormatException('Invalid records.');
        }
        final childIds = <String>{};
        for (final child in children) {
          if (child is! Map<String, dynamic>) {
            throw const FormatException('Invalid record.');
          }
          _text(child, 'id', required: true);
          if (!childIds.add(child['id'] as String)) {
            throw const FormatException('Duplicate record ID.');
          }
          if (child['student_id'] != row['id']) {
            throw const FormatException('Record belongs to another student.');
          }
          _integer(child, 'grade_level', 9, 12);
          _text(child, 'year_label', required: true);
          _text(child, 'description');
          if (kind == 'enrollments') {
            _text(child, 'course_title', required: true);
            _text(child, 'subject_category', required: true);
            _number(child, 'credit_hours', 0.01, 99);
            _number(child, 'weight_multiplier', 1, 10);
            if (child['is_pass_fail'] is! bool ||
                child['is_weighted'] is! bool) {
              throw const FormatException('Invalid grade settings.');
            }
            _text(child, 'grade_letter', required: true);
            final grade = (child['grade_letter'] as String)
                .trim()
                .toUpperCase();
            if (child['is_pass_fail'] == true
                ? !['PASS', 'FAIL'].contains(grade)
                : !gradePointTable.containsKey(grade)) {
              throw const FormatException('Unknown grade.');
            }
            child['grade_letter'] = grade;
          } else {
            for (final key
                in kind == 'awards'
                    ? ['name', 'organization', 'category']
                    : ['type', 'title', 'organization']) {
              _text(child, key, required: true);
            }
            if (kind == 'activities') _number(child, 'hours', 0, 100000);
          }
        }
      }
    }
    return rows
        .map((row) => StudentRecord.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static void _text(
    Map<String, dynamic> row,
    String field, {
    bool required = false,
  }) {
    final value = row[field];
    if (!required && value == null) return;
    if (value is! String ||
        value.length > 20000 ||
        (required && value.trim().isEmpty)) {
      throw FormatException('Invalid $field.');
    }
  }

  static void _integer(
    Map<String, dynamic> row,
    String field,
    int min,
    int max,
  ) {
    final value = row[field];
    if (value is! int || value < min || value > max) {
      throw FormatException('Invalid $field.');
    }
  }

  static void _number(
    Map<String, dynamic> row,
    String field,
    double min,
    double max,
  ) {
    final value = row[field];
    if (value is! num || !value.isFinite || value < min || value > max) {
      throw FormatException('Invalid $field.');
    }
  }
}

typedef SaveBytes = Future<bool> Function(Uint8List bytes);

class SaveCancelled implements Exception {
  @override
  String toString() => 'Save cancelled. Your edits are still here.';
}

class LocalStudentStore {
  LocalStudentStore({SaveBytes? saveBytes})
    : _saveBytes = saveBytes ?? _saveToDevice;
  final SaveBytes _saveBytes;
  List<StudentRecord> _students = [];
  bool hasUnsavedChanges = false;
  Future<List<StudentRecord>> fetchStudents() async =>
      List.unmodifiable(_students);
  Future<StudentRecord> createStudent(StudentRecord student) async {
    _students = [..._students, student];
    _dirty(true);
    return student;
  }

  Future<void> deleteStudent(String id) async {
    _students = _students.where((student) => student.id != id).toList();
    _dirty(true);
  }

  Future<StudentRecord> saveStudent(StudentRecord student) async {
    final next = [
      for (final existing in _students)
        if (existing.id == student.id) student else existing,
    ];
    // Commit session state only once saving has succeeded; cancellation preserves edits.
    if (!await _saveBytes(_validatedBytes(next))) throw SaveCancelled();
    _students = next;
    _dirty(false);
    return student;
  }

  Future<bool> saveFile() async {
    if (!await _saveBytes(_validatedBytes(_students))) return false;
    _dirty(false);
    return true;
  }

  void importBytes(Uint8List bytes) {
    final next = TranscriptFile.decode(bytes);
    _students = next;
    _dirty(false);
  }

  Future<bool> openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw const FormatException('Unable to read file.');
    importBytes(bytes);
    return true;
  }

  static Uint8List _validatedBytes(List<StudentRecord> students) {
    final bytes = TranscriptFile.encode(students);
    TranscriptFile.decode(bytes);
    return bytes;
  }

  static Future<bool> _saveToDevice(Uint8List bytes) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save all transcript records',
      fileName: 'transcript-records.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return kIsWeb || result != null;
  }

  void _dirty(bool value) {
    hasUnsavedChanges = value;
    setUnsavedChanges(value);
  }
}
