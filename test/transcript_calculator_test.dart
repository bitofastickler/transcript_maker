import 'package:flutter_test/flutter_test.dart';
import 'package:transcript_maker/transcript_calculator.dart';
import 'fixtures.dart';

void main() {
  test('GPA is credit weighted and failures earn no credit', () {
    final snapshot = TranscriptCalculator(
      student(
        courses: [
          course('A', credits: 0.5),
          course('F', id: '2'),
        ],
      ),
    ).build();
    expect(snapshot.unweightedGpa, closeTo(4 / 3, 0.00001));
    expect(snapshot.attemptedCredits, 1.5);
    expect(snapshot.earnedCredits, 0.5);
  });
  test('pass fail courses affect credits but not GPA', () {
    final snapshot = TranscriptCalculator(
      student(
        courses: [
          course('Pass', passFail: true),
          course('Fail', id: '2', passFail: true),
          course('B', id: '3'),
        ],
      ),
    ).build();
    expect(snapshot.unweightedGpa, 3);
    expect(snapshot.earnedCredits, 2);
  });
  test('weight multiplier applies only when weighted is enabled', () {
    expect(
      TranscriptCalculator.gpaFor([
        course('A', multiplier: 1.25),
      ], weighted: true),
      4,
    );
    expect(
      TranscriptCalculator.gpaFor([
        course('A', weighted: true, multiplier: 1.25),
      ], weighted: true),
      5,
    );
  });
  test('empty transcript and quarter credits display accurately', () {
    expect(TranscriptCalculator(student()).build().unweightedGpa, 0);
    expect(
      TranscriptCalculator(
        student(courses: [course('A', credits: 0.25)]),
      ).build().earnedCreditsString,
      '0.25',
    );
  });
}
