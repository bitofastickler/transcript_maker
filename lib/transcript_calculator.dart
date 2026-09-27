import 'models/student.dart';

class TranscriptSnapshot {
  const TranscriptSnapshot({
    required this.weightedGpa,
    required this.unweightedGpa,
    required this.earnedCredits,
    required this.attemptedCredits,
  });

  final double weightedGpa;
  final double unweightedGpa;
  final double earnedCredits;
  final double attemptedCredits;

  String get weightedGpaString => weightedGpa.toStringAsFixed(2);
  String get unweightedGpaString => unweightedGpa.toStringAsFixed(2);
  String get earnedCreditsString => earnedCredits.toStringAsFixed(2);
  String get attemptedCreditsString => attemptedCredits.toStringAsFixed(2);
}

class TranscriptCalculator {
  TranscriptCalculator(this.student);

  final StudentRecord student;

  TranscriptSnapshot build() {
    final enrollments = student.enrollments;
    final attemptedCredits = _attemptedCredits(enrollments);
    final earnedCredits = _earnedCredits(enrollments);
    final unweightedGpa = gpaFor(enrollments);
    final weightedGpa = gpaFor(enrollments, weighted: true);
    return TranscriptSnapshot(
      weightedGpa: weightedGpa,
      unweightedGpa: unweightedGpa,
      earnedCredits: earnedCredits,
      attemptedCredits: attemptedCredits,
    );
  }

  static double gpaFor(List<Enrollment> enrollments, {bool weighted = false}) {
    final gpaEnrollments = enrollments.where((e) => e.countsTowardGpa).toList();
    final credits = gpaEnrollments.fold<double>(
      0,
      (sum, e) => sum + e.creditHours,
    );
    if (credits == 0) {
      return 0;
    }
    final qualityPoints = gpaEnrollments.fold<double>(0, (sum, e) {
      final base = e.gradePoints ?? 0;
      final weight = weighted && e.isWeighted ? e.weightMultiplier : 1.0;
      return sum + base * e.creditHours * weight;
    });
    return qualityPoints / credits;
  }

  static double _attemptedCredits(List<Enrollment> enrollments) {
    return enrollments.fold<double>(0, (sum, e) => sum + e.creditHours);
  }

  static double _earnedCredits(List<Enrollment> enrollments) {
    double total = 0;
    for (final enrollment in enrollments) {
      if (enrollment.isPassFail) {
        if (enrollment.gradeLetter.toLowerCase() == 'pass') {
          total += enrollment.creditHours;
        }
      } else {
        if ((enrollment.gradePoints ?? -1) > 0) {
          total += enrollment.creditHours;
        }
      }
    }
    return total;
  }
}
