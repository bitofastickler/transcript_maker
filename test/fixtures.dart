import 'package:transcript_maker/models/student.dart';

StudentRecord student({List<Enrollment> courses = const []}) => StudentRecord(
  id: 'demo-student',
  firstName: 'Alex',
  lastName: 'Example',
  dateOfBirth: DateTime(2010, 3, 14),
  targetGradYear: 2028,
  enrollments: courses,
  awards: const [
    Award(
      id: 'award-1',
      studentId: 'demo-student',
      name: 'Example award',
      description: '',
      organization: 'Example school',
      category: 'Academic',
      yearLabel: '2025-2026',
      gradeLevel: 10,
    ),
  ],
  activities: const [
    Activity(
      id: 'activity-1',
      studentId: 'demo-student',
      type: 'Volunteer',
      title: 'Example activity',
      description: '',
      organization: 'Example group',
      hours: 12.5,
      yearLabel: '2025-2026',
      gradeLevel: 10,
    ),
  ],
);
Enrollment course(
  String grade, {
  String id = 'course-1',
  double credits = 1,
  bool passFail = false,
  bool weighted = false,
  double multiplier = 1,
}) => Enrollment(
  id: id,
  studentId: 'demo-student',
  gradeLevel: GradeLevel.grade10,
  yearLabel: '2025-2026',
  courseTitle: 'Example course',
  subjectCategory: 'English',
  description: '',
  creditHours: credits,
  gradeLetter: grade,
  isPassFail: passFail,
  isWeighted: weighted,
  weightMultiplier: multiplier,
);
