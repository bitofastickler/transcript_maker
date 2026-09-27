class StudentRecord {
  const StudentRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.targetGradYear,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.enrollments = const [],
    this.awards = const [],
    this.activities = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final int targetGradYear;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final List<Enrollment> enrollments;
  final List<Award> awards;
  final List<Activity> activities;

  String get fullName => '$firstName $lastName';

  StudentRecord copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    int? targetGradYear,
    String? email,
    String? phone,
    String? address,
    String? notes,
    List<Enrollment>? enrollments,
    List<Award>? awards,
    List<Activity>? activities,
  }) {
    return StudentRecord(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      targetGradYear: targetGradYear ?? this.targetGradYear,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      enrollments: enrollments ?? this.enrollments,
      awards: awards ?? this.awards,
      activities: activities ?? this.activities,
    );
  }

  factory StudentRecord.fromMap(Map<String, dynamic> row) {
    final enrollmentsData = _asList(
      row['enrollments'],
    ).map((item) => Enrollment.fromMap(item)).toList();
    final awardsData = _asList(
      row['awards'],
    ).map((item) => Award.fromMap(item)).toList();
    final activitiesData = _asList(
      row['activities'],
    ).map((item) => Activity.fromMap(item)).toList();
    return StudentRecord(
      id: row['id'] as String,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      dateOfBirth: _parseDate(row['date_of_birth'])!,
      targetGradYear: (row['target_grad_year'] as num).toInt(),
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
      notes: row['notes'] as String?,
      enrollments: enrollmentsData,
      awards: awardsData,
      activities: activitiesData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'target_grad_year': targetGradYear,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'enrollments': enrollments.map((e) => e.toMap()).toList(),
      'awards': awards.map((e) => e.toMap()).toList(),
      'activities': activities.map((e) => e.toMap()).toList(),
    };
  }
}

enum GradeLevel {
  grade9(9, '9th Grade'),
  grade10(10, '10th Grade'),
  grade11(11, '11th Grade'),
  grade12(12, '12th Grade');

  const GradeLevel(this.value, this.label);

  final int value;
  final String label;
}

class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.gradeLevel,
    required this.yearLabel,
    required this.courseTitle,
    required this.subjectCategory,
    required this.description,
    required this.creditHours,
    required this.gradeLetter,
    this.isPassFail = false,
    this.isWeighted = false,
    this.weightMultiplier = 1.0,
  });

  final String id;
  final String studentId;
  final GradeLevel gradeLevel;
  final String yearLabel;
  final String courseTitle;
  final String subjectCategory;
  final String description;
  final double creditHours;
  final String gradeLetter;
  final bool isPassFail;
  final bool isWeighted;
  final double weightMultiplier;

  bool get countsTowardGpa => !isPassFail && gradePoints != null;
  double? get gradePoints => gradePointTable[gradeLetter.toUpperCase()];

  factory Enrollment.fromMap(Map<String, dynamic> row) {
    return Enrollment(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      gradeLevel: _gradeLevelFromValue((row['grade_level'] as num).toInt()),
      yearLabel: row['year_label'] as String? ?? '',
      courseTitle: row['course_title'] as String? ?? '',
      subjectCategory: row['subject_category'] as String? ?? '',
      description: row['description'] as String? ?? '',
      creditHours: _parseDouble(row['credit_hours']) ?? 0,
      gradeLetter: row['grade_letter'] as String? ?? '',
      isPassFail: row['is_pass_fail'] as bool? ?? false,
      isWeighted: row['is_weighted'] as bool? ?? false,
      weightMultiplier: _parseDouble(row['weight_multiplier']) ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'grade_level': gradeLevel.value,
      'year_label': yearLabel,
      'course_title': courseTitle,
      'subject_category': subjectCategory,
      'description': description,
      'credit_hours': creditHours,
      'grade_letter': gradeLetter,
      'is_pass_fail': isPassFail,
      'is_weighted': isWeighted,
      'weight_multiplier': weightMultiplier,
    };
  }
}

class Award {
  const Award({
    required this.id,
    required this.studentId,
    required this.name,
    required this.description,
    required this.organization,
    required this.category,
    required this.yearLabel,
    required this.gradeLevel,
  });

  final String id;
  final String studentId;
  final String name;
  final String description;
  final String organization;
  final String category;
  final String yearLabel;
  final int gradeLevel;

  factory Award.fromMap(Map<String, dynamic> row) {
    return Award(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      name: row['name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      organization: row['organization'] as String? ?? '',
      category: row['category'] as String? ?? '',
      yearLabel: row['year_label'] as String? ?? '',
      gradeLevel:
          (row['grade_level'] as num?)?.toInt() ?? GradeLevel.grade9.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'description': description,
      'organization': organization,
      'category': category,
      'year_label': yearLabel,
      'grade_level': gradeLevel,
    };
  }
}

class Activity {
  const Activity({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    required this.description,
    required this.organization,
    required this.hours,
    required this.yearLabel,
    required this.gradeLevel,
  });

  final String id;
  final String studentId;
  final String type;
  final String title;
  final String description;
  final String organization;
  final double hours;
  final String yearLabel;
  final int gradeLevel;

  factory Activity.fromMap(Map<String, dynamic> row) {
    return Activity(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      type: row['type'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      organization: row['organization'] as String? ?? '',
      hours: _parseDouble(row['hours']) ?? 0,
      yearLabel: row['year_label'] as String? ?? '',
      gradeLevel:
          (row['grade_level'] as num?)?.toInt() ?? GradeLevel.grade9.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'type': type,
      'title': title,
      'description': description,
      'organization': organization,
      'hours': hours,
      'year_label': yearLabel,
      'grade_level': gradeLevel,
    };
  }
}

final Map<String, double> gradePointTable = {
  'A+': 4.0,
  'A': 4.0,
  'A-': 3.7,
  'B+': 3.3,
  'B': 3.0,
  'B-': 2.7,
  'C+': 2.3,
  'C': 2.0,
  'C-': 1.7,
  'D+': 1.3,
  'D': 1.0,
  'D-': 0.7,
  'F': 0.0,
};

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

GradeLevel _gradeLevelFromValue(int value) {
  return GradeLevel.values.firstWhere(
    (level) => level.value == value,
    orElse: () => GradeLevel.grade9,
  );
}
