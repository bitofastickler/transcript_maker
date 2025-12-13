import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const HomeschoolLedgerApp());
}

class HomeschoolLedgerApp extends StatelessWidget {
  const HomeschoolLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homeschool Transcript Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(232, 2, 139, 219)),
        useMaterial3: true,
      ),
      home: const StudentsPage(),
    );
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  late List<StudentRecord> _students;

  @override
  void initState() {
    super.initState();
    _students = List.of(SampleData.students);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final student = _students[index];
          final snapshot = TranscriptCalculator(student).build();
          return _StudentCard(
            student: student,
            snapshot: snapshot,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentDetailPage(
                  student: student,
                  onStudentUpdated: _handleStudentUpdated,
                  onStudentDeleted: _handleStudentDeleted,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _students.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStudentForm,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  void _handleStudentUpdated(StudentRecord updated) {
    setState(() {
      _students = [
        for (final student in _students)
          if (student.id == updated.id) updated else student,
      ];
    });
  }

  Future<void> _openStudentForm() async {
    final createdStudent = await showModalBottomSheet<StudentRecord>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const StudentFormSheet(),
    );
    if (createdStudent == null) return;
    setState(() {
      _students = [..._students, createdStudent];
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Student ${createdStudent.fullName} added')),
    );
  }

  void _handleStudentDeleted(StudentRecord student) {
    setState(() {
      _students = [
        for (final existing in _students)
          if (existing.id != student.id) existing,
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Student ${student.fullName} deleted')),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.snapshot,
    required this.onTap,
  });

  final StudentRecord student;
  final TranscriptSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('Class of ${student.targetGradYear}'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: 'Weighted GPA',
                    value: snapshot.weightedGpaString,
                  ),
                  _MetricChip(
                    label: 'Unweighted GPA',
                    value: snapshot.unweightedGpaString,
                  ),
                  _MetricChip(
                    label: 'Credits',
                    value: snapshot.earnedCreditsString,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({
    super.key,
    required this.student,
    required this.onStudentUpdated,
    required this.onStudentDeleted,
  });

  final StudentRecord student;
  final ValueChanged<StudentRecord> onStudentUpdated;
  final ValueChanged<StudentRecord> onStudentDeleted;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late StudentRecord _student;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  TranscriptSnapshot get _snapshot => TranscriptCalculator(_student).build();

  void _updateStudent(StudentRecord updated) {
    setState(() {
      _student = updated;
    });
    widget.onStudentUpdated(updated);
  }

  Future<void> _addClass() async {
    final draft = await showModalBottomSheet<EnrollmentDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EnrollmentFormSheet(student: _student),
    );
    if (draft == null) return;

    final enrollment = Enrollment(
      id: _generateId('enroll'),
      studentId: _student.id,
      gradeLevel: draft.gradeLevel,
      yearLabel: draft.yearLabel,
      courseTitle: draft.courseTitle,
      subjectCategory: draft.subjectCategory,
      description: draft.description,
      creditHours: draft.creditHours,
      gradeLetter: draft.gradeLetter,
      isPassFail: draft.isPassFail,
      isWeighted: draft.isWeighted,
      weightMultiplier: draft.isWeighted ? draft.weightMultiplier : 1.0,
    );

    _updateStudent(
      _student.copyWith(enrollments: [..._student.enrollments, enrollment]),
    );
  }

  Future<void> _addAward() async {
    final draft = await showModalBottomSheet<AwardDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AwardFormSheet(student: _student),
    );
    if (draft == null) return;

    final award = Award(
      id: _generateId('award'),
      studentId: _student.id,
      name: draft.name,
      description: draft.description,
      organization: draft.organization,
      category: draft.category,
      yearLabel: draft.yearLabel,
      gradeLevel: draft.gradeLevel.value,
    );

    _updateStudent(_student.copyWith(awards: [..._student.awards, award]));
  }

  Future<void> _addActivity() async {
    final draft = await showModalBottomSheet<ActivityDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ActivityFormSheet(student: _student),
    );
    if (draft == null) return;

    final activity = Activity(
      id: _generateId('activity'),
      studentId: _student.id,
      type: draft.type,
      title: draft.title,
      description: draft.description,
      organization: draft.organization,
      hours: draft.hours,
      yearLabel: draft.yearLabel,
      gradeLevel: draft.gradeLevel.value,
    );

    _updateStudent(
      _student.copyWith(activities: [..._student.activities, activity]),
    );
  }

  Future<void> _editStudent() async {
    final updatedStudent = await showModalBottomSheet<StudentRecord>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentFormSheet(initialStudent: _student),
    );
    if (updatedStudent == null) return;
    _updateStudent(updatedStudent);
  }

  Future<void> _editClass(Enrollment enrollment) async {
    final draft = await showModalBottomSheet<EnrollmentDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          EnrollmentFormSheet(student: _student, initialEnrollment: enrollment),
    );
    if (draft == null) return;

    final updatedEnrollment = Enrollment(
      id: enrollment.id,
      studentId: _student.id,
      gradeLevel: draft.gradeLevel,
      yearLabel: draft.yearLabel,
      courseTitle: draft.courseTitle,
      subjectCategory: draft.subjectCategory,
      description: draft.description,
      creditHours: draft.creditHours,
      gradeLetter: draft.gradeLetter,
      isPassFail: draft.isPassFail,
      isWeighted: draft.isWeighted,
      weightMultiplier: draft.isWeighted ? draft.weightMultiplier : 1.0,
    );

    _updateStudent(
      _student.copyWith(
        enrollments: [
          for (final current in _student.enrollments)
            if (current.id == enrollment.id) updatedEnrollment else current,
        ],
      ),
    );
  }

  Future<void> _editAward(Award award) async {
    final draft = await showModalBottomSheet<AwardDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          AwardFormSheet(student: _student, initialAward: award),
    );
    if (draft == null) return;

    final updatedAward = Award(
      id: award.id,
      studentId: _student.id,
      name: draft.name,
      description: draft.description,
      organization: draft.organization,
      category: draft.category,
      yearLabel: draft.yearLabel,
      gradeLevel: draft.gradeLevel.value,
    );

    _updateStudent(
      _student.copyWith(
        awards: [
          for (final current in _student.awards)
            if (current.id == award.id) updatedAward else current,
        ],
      ),
    );
  }

  Future<void> _editActivity(Activity activity) async {
    final draft = await showModalBottomSheet<ActivityDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ActivityFormSheet(student: _student, initialActivity: activity),
    );
    if (draft == null) return;

    final updatedActivity = Activity(
      id: activity.id,
      studentId: _student.id,
      type: draft.type,
      title: draft.title,
      description: draft.description,
      organization: draft.organization,
      hours: draft.hours,
      yearLabel: draft.yearLabel,
      gradeLevel: draft.gradeLevel.value,
    );

    _updateStudent(
      _student.copyWith(
        activities: [
          for (final current in _student.activities)
            if (current.id == activity.id) updatedActivity else current,
        ],
      ),
    );
  }

  Future<void> _deleteClass(Enrollment enrollment) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete class?'),
            content: Text(
              'Remove ${enrollment.courseTitle} from ${_student.fullName}? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    _updateStudent(
      _student.copyWith(
        enrollments: [
          for (final current in _student.enrollments)
            if (current.id != enrollment.id) current,
        ],
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Class ${enrollment.courseTitle} deleted')),
    );
  }

  Future<void> _deleteAward(Award award) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete award?'),
            content: Text(
              'Remove ${award.name} from ${_student.fullName}? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    _updateStudent(
      _student.copyWith(
        awards: [
          for (final current in _student.awards)
            if (current.id != award.id) current,
        ],
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Award ${award.name} deleted')),
    );
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete activity?'),
            content: Text(
              'Remove ${activity.title} from ${_student.fullName}? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    _updateStudent(
      _student.copyWith(
        activities: [
          for (final current in _student.activities)
            if (current.id != activity.id) current,
        ],
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Activity ${activity.title} deleted')),
    );
  }

  Future<void> _deleteStudent() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete student?'),
            content: Text(
              'Are you sure you want to delete ${_student.fullName}? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    widget.onStudentDeleted(_student);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  FloatingActionButton _buildFab() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: _addAward,
          icon: const Icon(Icons.emoji_events),
          label: const Text('Add Award'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: _addActivity,
          icon: const Icon(Icons.group),
          label: const Text('Add Activity'),
        );
      case 0:
      default:
        return FloatingActionButton.extended(
          onPressed: _addClass,
          icon: const Icon(Icons.class_),
          label: const Text('Add Class'),
        );
    }
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: Text(_student.fullName),
        actions: [
          IconButton(
            tooltip: 'Edit student',
            icon: const Icon(Icons.edit),
            onPressed: _editStudent,
          ),
          IconButton(
            tooltip: 'Delete student',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteStudent,
          ),
          IconButton(
            tooltip: 'Export transcript to PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => TranscriptPdfService.export(
              context: context,
              student: _student,
              snapshot: snapshot,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Classes'),
            Tab(text: 'Awards'),
            Tab(text: 'Activities'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          StudentSummaryHeader(student: _student, snapshot: snapshot),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ClassesTab(
                  student: _student,
                  onEditEnrollment: _editClass,
                  onDeleteEnrollment: _deleteClass,
                ),
                AwardsTab(
                  student: _student,
                  onEditAward: _editAward,
                  onDeleteAward: _deleteAward,
                ),
                ActivitiesTab(
                  student: _student,
                  onEditActivity: _editActivity,
                  onDeleteActivity: _deleteActivity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSummaryHeader extends StatelessWidget {
  const StudentSummaryHeader({
    super.key,
    required this.student,
    required this.snapshot,
  });

  final StudentRecord student;
  final TranscriptSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${student.fullName} • Class of ${student.targetGradYear}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('DOB: ${_formatDate(student.dateOfBirth)}'),
            if (student.email != null || student.phone != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (student.email != null) student.email!,
                  if (student.phone != null) student.phone!,
                ].join(' • '),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Weighted GPA',
                  value: snapshot.weightedGpaString,
                  highlight: true,
                ),
                _MetricChip(
                  label: 'Unweighted GPA',
                  value: snapshot.unweightedGpaString,
                ),
                _MetricChip(
                  label: 'Credits Earned',
                  value: snapshot.earnedCreditsString,
                ),
                _MetricChip(
                  label: 'Credits Attempted',
                  value: snapshot.attemptedCreditsString,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClassesTab extends StatelessWidget {
  const ClassesTab({
    super.key,
    required this.student,
    required this.onEditEnrollment,
    required this.onDeleteEnrollment,
  });

  final StudentRecord student;
  final void Function(Enrollment enrollment) onEditEnrollment;
  final void Function(Enrollment enrollment) onDeleteEnrollment;

  @override
  Widget build(BuildContext context) {
    final yearGroups = _groupEnrollments(student.enrollments);
    if (yearGroups.isEmpty) {
      return const EmptyState(message: 'No classes logged yet.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: yearGroups.length,
      itemBuilder: (context, index) {
        final group = yearGroups[index];
        final groupGpa = TranscriptCalculator.gpaFor(group.enrollments);
        final groupWeightedGpa = TranscriptCalculator.gpaFor(
          group.enrollments,
          weighted: true,
        );
        final credits = group.enrollments.fold<double>(
          0,
          (sum, e) => sum + e.creditHours,
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.yearLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          group.gradeLevel.label,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('GPA ${groupGpa.toStringAsFixed(2)}'),
                        Text('Weighted ${groupWeightedGpa.toStringAsFixed(2)}'),
                        Text('${credits.toStringAsFixed(1)} credits'),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...group.enrollments.map(
                  (enrollment) => _EnrollmentTile(
                    enrollment: enrollment,
                    onTap: () => onEditEnrollment(enrollment),
                    onDelete: () => onDeleteEnrollment(enrollment),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AwardsTab extends StatelessWidget {
  const AwardsTab({
    super.key,
    required this.student,
    required this.onEditAward,
    required this.onDeleteAward,
  });

  final StudentRecord student;
  final void Function(Award award) onEditAward;
  final void Function(Award award) onDeleteAward;

  @override
  Widget build(BuildContext context) {
    final awards = student.awards;
    if (awards.isEmpty) {
      return const EmptyState(message: 'No awards or recognitions logged yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final award = awards[index];
        return _AwardTile(
          award: award,
          onTap: () => onEditAward(award),
          onDelete: () => onDeleteAward(award),
        );
      },
      separatorBuilder: (_, __) => const Divider(),
      itemCount: awards.length,
    );
  }
}

class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({
    super.key,
    required this.student,
    required this.onEditActivity,
    required this.onDeleteActivity,
  });

  final StudentRecord student;
  final void Function(Activity activity) onEditActivity;
  final void Function(Activity activity) onDeleteActivity;

  @override
  Widget build(BuildContext context) {
    final activities = student.activities;
    if (activities.isEmpty) {
      return const EmptyState(message: 'No activities logged yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _ActivityTile(
          activity: activity,
          onTap: () => onEditActivity(activity),
          onDelete: () => onDeleteActivity(activity),
        );
      },
      separatorBuilder: (_, __) => const Divider(),
      itemCount: activities.length,
    );
  }
}

class _EnrollmentTile extends StatelessWidget {
  const _EnrollmentTile({
    required this.enrollment,
    required this.onTap,
    required this.onDelete,
  });

  final Enrollment enrollment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.courseTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(enrollment.subjectCategory),
                      if (enrollment.description.isNotEmpty)
                        Text(
                          enrollment.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: colorScheme.primary,
                          tooltip: 'Edit class',
                          onPressed: onTap,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: colorScheme.error,
                          tooltip: 'Delete class',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enrollment.gradeLetter,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${enrollment.creditHours.toStringAsFixed(1)} credits',
                    ),
                    if (enrollment.isWeighted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_graph, size: 16),
                          SizedBox(width: 4),
                          Text('Weighted'),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

class _AwardTile extends StatelessWidget {
  const _AwardTile({
    required this.award,
    required this.onTap,
    required this.onDelete,
  });

  final Award award;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text('${award.gradeLevel}')),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    award.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${award.organization} • ${award.yearLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (award.description.isNotEmpty)
                    Text(
                      award.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: colorScheme.primary,
                      tooltip: 'Edit award',
                      onPressed: onTap,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: colorScheme.error,
                      tooltip: 'Delete award',
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Grade ${award.gradeLevel}'),
                Text(award.category),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.onTap,
    required this.onDelete,
  });

  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Text('${activity.hours.toStringAsFixed(0)}h'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${activity.organization} • ${activity.yearLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (activity.description.isNotEmpty)
                    Text(
                      activity.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: colorScheme.primary,
                      tooltip: 'Edit activity',
                      onPressed: onTap,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: colorScheme.error,
                      tooltip: 'Delete activity',
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(activity.type),
                Text('Grade ${activity.gradeLevel}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlight
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = highlight
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: foreground),
          ),
        ],
      ),
      backgroundColor: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

const String _otherOptionLabel = 'Other';

const List<String> _subjectCategoryOptions = [
  'Mathematics',
  'Science',
  'English / Language Arts',
  'History / Social Studies',
  'Foreign Language',
  'Fine Arts',
  'Physical Education',
  'Technology',
  'Elective',
  _otherOptionLabel,
];

const List<String> _awardCategoryOptions = [
  'Academic',
  'Leadership',
  'Community Service',
  'Arts',
  'Athletic',
  'STEM',
  _otherOptionLabel,
];

const List<String> _activityTypeOptions = [
  'Volunteer',
  'Club',
  'Athletics',
  'Arts',
  'Employment',
  'Internship',
  'Competition',
  'Camp',
  _otherOptionLabel,
];

String? _matchOptionIgnoringCase(String value, List<String> options) {
  final normalized = value.trim().toLowerCase();
  for (final option in options) {
    if (option.toLowerCase() == normalized) {
      return option;
    }
  }
  return null;
}

class StudentFormSheet extends StatefulWidget {
  const StudentFormSheet({super.key, this.initialStudent});

  final StudentRecord? initialStudent;

  bool get isEditing => initialStudent != null;

  @override
  State<StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends State<StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dob;
  bool _dobTouched = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStudent;
    if (initial != null) {
      _firstNameController.text = initial.firstName;
      _lastNameController.text = initial.lastName;
      _gradYearController.text = initial.targetGradYear.toString();
      _emailController.text = initial.email ?? '';
      _phoneController.text = initial.phone ?? '';
      _dob = initial.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _gradYearController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit Student' : 'Add Student',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Date of birth',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDob,
                icon: const Icon(Icons.cake),
                label: Text(_dob == null ? 'Select date' : _formatDate(_dob!)),
              ),
              if (_dobTouched && _dob == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Date of birth is required',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradYearController,
                decoration: const InputDecoration(
                  labelText: 'Target graduation year',
                  hintText: 'e.g. 2026',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed < 2020 || parsed > 2040) {
                    return 'Enter a year between 2020 and 2040';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final earliest = DateTime(now.year - 25);
    final latest = DateTime(now.year - 5, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 14, now.month, now.day),
      firstDate: earliest,
      lastDate: latest,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _dobTouched = true;
    });
    if (!valid || _dob == null) {
      return;
    }
    final gradYear = int.parse(_gradYearController.text);
    final trimmedEmail = _emailController.text.trim();
    final trimmedPhone = _phoneController.text.trim();
    final email = trimmedEmail.isEmpty ? null : trimmedEmail;
    final phone = trimmedPhone.isEmpty ? null : trimmedPhone;

    if (widget.initialStudent != null) {
      final existing = widget.initialStudent!;
      final updated = StudentRecord(
        id: existing.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dob!,
        targetGradYear: gradYear,
        email: email,
        phone: phone,
        address: existing.address,
        notes: existing.notes,
        enrollments: existing.enrollments,
        awards: existing.awards,
        activities: existing.activities,
      );
      Navigator.of(context).pop(updated);
      return;
    }

    final student = StudentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dob!,
      targetGradYear: gradYear,
      email: email,
      phone: phone,
    );
    Navigator.of(context).pop(student);
  }
}

class EnrollmentDraft {
  EnrollmentDraft({
    required this.gradeLevel,
    required this.yearLabel,
    required this.courseTitle,
    required this.subjectCategory,
    required this.description,
    required this.creditHours,
    required this.gradeLetter,
    required this.isWeighted,
    required this.isPassFail,
    required this.weightMultiplier,
  });

  final GradeLevel gradeLevel;
  final String yearLabel;
  final String courseTitle;
  final String subjectCategory;
  final String description;
  final double creditHours;
  final String gradeLetter;
  final bool isWeighted;
  final bool isPassFail;
  final double weightMultiplier;
}

class EnrollmentFormSheet extends StatefulWidget {
  const EnrollmentFormSheet({
    super.key,
    required this.student,
    this.initialEnrollment,
  });

  final StudentRecord student;
  final Enrollment? initialEnrollment;

  bool get isEditing => initialEnrollment != null;

  @override
  State<EnrollmentFormSheet> createState() => _EnrollmentFormSheetState();
}

class _EnrollmentFormSheetState extends State<EnrollmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _courseController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _gradeLetterController = TextEditingController(text: 'A');
  final _creditsController = TextEditingController(text: '1.0');
  final _weightMultiplierController = TextEditingController(text: '1.0');
  GradeLevel _gradeLevel = GradeLevel.grade9;
  bool _isWeighted = false;
  bool _isPassFail = false;
  late String _selectedSubjectOption;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEnrollment;
    String? subjectCategory;
    if (initial != null) {
      _gradeLevel = initial.gradeLevel;
      _yearController.text = initial.yearLabel;
      _courseController.text = initial.courseTitle;
      _descriptionController.text = initial.description;
      _gradeLetterController.text = initial.gradeLetter;
      final creditsText = initial.creditHours.toStringAsFixed(
        initial.creditHours % 1 == 0 ? 0 : 2,
      );
      _creditsController.text = creditsText;
      _isWeighted = initial.isWeighted;
      _isPassFail = initial.isPassFail;
      _weightMultiplierController.text = initial.weightMultiplier.toString();
      if (!initial.isWeighted) {
        _weightMultiplierController.text = '1.0';
      }
      subjectCategory = initial.subjectCategory;
    } else if (widget.student.enrollments.isNotEmpty) {
      final last = widget.student.enrollments.last;
      _gradeLevel = last.gradeLevel;
      _yearController.text = last.yearLabel;
      subjectCategory = last.subjectCategory;
    } else {
      final now = DateTime.now();
      _yearController.text = '${now.year}-${now.year + 1}';
      subjectCategory = _subjectCategoryOptions.first;
    }
    _initializeSubjectCategory(subjectCategory);
  }

  void _initializeSubjectCategory(String? category) {
    final trimmed = category?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final match = _matchOptionIgnoringCase(trimmed, _subjectCategoryOptions);
      if (match != null && match != _otherOptionLabel) {
        _selectedSubjectOption = match;
        _subjectController.text = match;
        return;
      }
      _selectedSubjectOption = _otherOptionLabel;
      _subjectController.text = trimmed;
      return;
    }
    _selectedSubjectOption = _subjectCategoryOptions.first;
    _subjectController.text = _subjectCategoryOptions.first;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _courseController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _gradeLetterController.dispose();
    _creditsController.dispose();
    _weightMultiplierController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    final credits = double.parse(_creditsController.text.trim());
    final weightMultiplier = _isWeighted
        ? double.parse(_weightMultiplierController.text.trim())
        : 1.0;
    final subjectCategory = _selectedSubjectOption == _otherOptionLabel
        ? _subjectController.text.trim()
        : _selectedSubjectOption;
    final draft = EnrollmentDraft(
      gradeLevel: _gradeLevel,
      yearLabel: _yearController.text.trim(),
      courseTitle: _courseController.text.trim(),
      subjectCategory: subjectCategory,
      description: _descriptionController.text.trim(),
      creditHours: credits,
      gradeLetter: _gradeLetterController.text.trim().toUpperCase(),
      isWeighted: _isWeighted,
      isPassFail: _isPassFail,
      weightMultiplier: weightMultiplier,
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit Class' : 'Add Class',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GradeLevel>(
                value: _gradeLevel,
                decoration: const InputDecoration(labelText: 'Grade level'),
                items: GradeLevel.values
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gradeLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Academic year',
                  hintText: 'e.g. 2024-2025',
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Course title'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubjectOption,
                decoration: const InputDecoration(labelText: 'Subject category'),
                items: _subjectCategoryOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedSubjectOption = value;
                    if (value != _otherOptionLabel) {
                      _subjectController.text = value;
                    } else if (_subjectController.text.trim().isEmpty) {
                      _subjectController.clear();
                    }
                  });
                },
              ),
              if (_selectedSubjectOption == _otherOptionLabel) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject category',
                    hintText: 'Enter category',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional summary of coursework',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeLetterController,
                decoration: const InputDecoration(labelText: 'Grade letter'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(labelText: 'Credits earned'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter credits greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Counts as pass / fail'),
                value: _isPassFail,
                onChanged: (value) {
                  setState(() {
                    _isPassFail = value;
                  });
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Weighted course'),
                value: _isWeighted,
                onChanged: (value) {
                  setState(() {
                    _isWeighted = value;
                    if (!value) {
                      _weightMultiplierController.text = '1.0';
                    }
                  });
                },
              ),
              if (_isWeighted) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightMultiplierController,
                  decoration: const InputDecoration(
                    labelText: 'Weight multiplier',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (!_isWeighted) {
                      return null;
                    }
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 1.0) {
                      return 'Enter a weight of 1.0 or higher';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AwardDraft {
  AwardDraft({
    required this.gradeLevel,
    required this.yearLabel,
    required this.name,
    required this.organization,
    required this.category,
    required this.description,
  });

  final GradeLevel gradeLevel;
  final String yearLabel;
  final String name;
  final String organization;
  final String category;
  final String description;
}

class AwardFormSheet extends StatefulWidget {
  const AwardFormSheet({super.key, required this.student, this.initialAward});

  final StudentRecord student;
  final Award? initialAward;

  bool get isEditing => initialAward != null;

  @override
  State<AwardFormSheet> createState() => _AwardFormSheetState();
}

class _AwardFormSheetState extends State<AwardFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  GradeLevel _gradeLevel = GradeLevel.grade9;
  late String _selectedCategoryOption;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAward;
    String? category;
    if (initial != null) {
      _gradeLevel = GradeLevel.values.firstWhere(
        (level) => level.value == initial.gradeLevel,
        orElse: () => GradeLevel.grade9,
      );
      _yearController.text = initial.yearLabel;
      _nameController.text = initial.name;
      _organizationController.text = initial.organization;
      _descriptionController.text = initial.description;
      category = initial.category;
    } else if (widget.student.awards.isNotEmpty) {
      final last = widget.student.awards.last;
      _gradeLevel = GradeLevel.values.firstWhere(
        (level) => level.value == last.gradeLevel,
        orElse: () => GradeLevel.grade9,
      );
      _yearController.text = last.yearLabel;
      category = last.category;
    } else if (widget.student.enrollments.isNotEmpty) {
      final lastEnrollment = widget.student.enrollments.last;
      _gradeLevel = lastEnrollment.gradeLevel;
      _yearController.text = lastEnrollment.yearLabel;
      category = _awardCategoryOptions.first;
    } else {
      category = _awardCategoryOptions.first;
    }
    _initializeCategory(category);
  }

  void _initializeCategory(String? category) {
    final trimmed = category?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final match = _matchOptionIgnoringCase(trimmed, _awardCategoryOptions);
      if (match != null && match != _otherOptionLabel) {
        _selectedCategoryOption = match;
        _categoryController.text = match;
        return;
      }
      _selectedCategoryOption = _otherOptionLabel;
      _categoryController.text = trimmed;
      return;
    }
    _selectedCategoryOption = _awardCategoryOptions.first;
    _categoryController.text = _awardCategoryOptions.first;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _nameController.dispose();
    _organizationController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    final category = _selectedCategoryOption == _otherOptionLabel
        ? _categoryController.text.trim()
        : _selectedCategoryOption;
    final draft = AwardDraft(
      gradeLevel: _gradeLevel,
      yearLabel: _yearController.text.trim(),
      name: _nameController.text.trim(),
      organization: _organizationController.text.trim(),
      category: category,
      description: _descriptionController.text.trim(),
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit Award' : 'Add Award',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GradeLevel>(
                value: _gradeLevel,
                decoration: const InputDecoration(labelText: 'Grade level'),
                items: GradeLevel.values
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gradeLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Academic year',
                  hintText: 'e.g. 2024-2025',
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Award name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizationController,
                decoration: const InputDecoration(labelText: 'Organization'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryOption,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _awardCategoryOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCategoryOption = value;
                    if (value != _otherOptionLabel) {
                      _categoryController.text = value;
                    } else if (_categoryController.text.trim().isEmpty) {
                      _categoryController.clear();
                    }
                  });
                },
              ),
              if (_selectedCategoryOption == _otherOptionLabel) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Custom category',
                    hintText: 'Enter category',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional details',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityDraft {
  ActivityDraft({
    required this.gradeLevel,
    required this.yearLabel,
    required this.type,
    required this.title,
    required this.organization,
    required this.description,
    required this.hours,
  });

  final GradeLevel gradeLevel;
  final String yearLabel;
  final String type;
  final String title;
  final String organization;
  final String description;
  final double hours;
}

class ActivityFormSheet extends StatefulWidget {
  const ActivityFormSheet({
    super.key,
    required this.student,
    this.initialActivity,
  });

  final StudentRecord student;
  final Activity? initialActivity;

  bool get isEditing => initialActivity != null;

  @override
  State<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _typeController = TextEditingController(text: 'Volunteer');
  final _titleController = TextEditingController();
  final _organizationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController(text: '1.0');
  GradeLevel _gradeLevel = GradeLevel.grade9;
  late String _selectedActivityType;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialActivity;
    String? activityType;
    if (initial != null) {
      _gradeLevel = GradeLevel.values.firstWhere(
        (level) => level.value == initial.gradeLevel,
        orElse: () => GradeLevel.grade9,
      );
      _yearController.text = initial.yearLabel;
      _titleController.text = initial.title;
      _organizationController.text = initial.organization;
      _descriptionController.text = initial.description;
      _hoursController.text = initial.hours.toStringAsFixed(
        initial.hours % 1 == 0 ? 0 : 2,
      );
      activityType = initial.type;
    } else if (widget.student.activities.isNotEmpty) {
      final last = widget.student.activities.last;
      _gradeLevel = GradeLevel.values.firstWhere(
        (level) => level.value == last.gradeLevel,
        orElse: () => GradeLevel.grade9,
      );
      _yearController.text = last.yearLabel;
      activityType = last.type;
    } else if (widget.student.enrollments.isNotEmpty) {
      final lastEnrollment = widget.student.enrollments.last;
      _gradeLevel = lastEnrollment.gradeLevel;
      _yearController.text = lastEnrollment.yearLabel;
      activityType = _activityTypeOptions.first;
    } else {
      activityType = _activityTypeOptions.first;
    }
    _initializeActivityType(activityType);
  }

  void _initializeActivityType(String? type) {
    final trimmed = type?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final match = _matchOptionIgnoringCase(trimmed, _activityTypeOptions);
      if (match != null && match != _otherOptionLabel) {
        _selectedActivityType = match;
        _typeController.text = match;
        return;
      }
      _selectedActivityType = _otherOptionLabel;
      _typeController.text = trimmed;
      return;
    }
    _selectedActivityType = _activityTypeOptions.first;
    _typeController.text = _activityTypeOptions.first;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _typeController.dispose();
    _titleController.dispose();
    _organizationController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    final activityType = _selectedActivityType == _otherOptionLabel
        ? _typeController.text.trim()
        : _selectedActivityType;
    final draft = ActivityDraft(
      gradeLevel: _gradeLevel,
      yearLabel: _yearController.text.trim(),
      type: activityType,
      title: _titleController.text.trim(),
      organization: _organizationController.text.trim(),
      description: _descriptionController.text.trim(),
      hours: double.parse(_hoursController.text.trim()),
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit Activity' : 'Add Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GradeLevel>(
                value: _gradeLevel,
                decoration: const InputDecoration(labelText: 'Grade level'),
                items: GradeLevel.values
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gradeLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Academic year',
                  hintText: 'e.g. 2024-2025',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedActivityType,
                decoration: const InputDecoration(labelText: 'Activity type'),
                items: _activityTypeOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedActivityType = value;
                    if (value != _otherOptionLabel) {
                      _typeController.text = value;
                    } else if (_typeController.text.trim().isEmpty) {
                      _typeController.clear();
                    }
                  });
                },
              ),
              if (_selectedActivityType == _otherOptionLabel) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Custom activity type',
                    hintText: 'Enter activity type',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Activity title'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizationController,
                decoration: const InputDecoration(labelText: 'Organization'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional details',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'Hours'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Enter zero or more hours';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  String get earnedCreditsString => earnedCredits.toStringAsFixed(1);
  String get attemptedCreditsString => attemptedCredits.toStringAsFixed(1);
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
      final weight = weighted ? e.weightMultiplier : 1.0;
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

class TranscriptPdfService {
  static Future<void> export({
    required BuildContext context,
    required StudentRecord student,
    required TranscriptSnapshot snapshot,
  }) async {
    try {
      final doc = pw.Document();
      final yearGroups = _groupEnrollments(student.enrollments);
      doc.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context _) => [
            _header(student),
            pw.SizedBox(height: 16),
            _summary(snapshot),
            if (yearGroups.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Course Work', style: _sectionTitle),
              pw.SizedBox(height: 8),
              ...yearGroups.map(_yearSection),
            ],
            if (student.awards.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Awards & Recognitions', style: _sectionTitle),
              pw.SizedBox(height: 8),
              _awardsSection(student.awards),
            ],
            if (student.activities.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Activities', style: _sectionTitle),
              pw.SizedBox(height: 8),
              _activitiesSection(student.activities),
            ],
          ],
        ),
      );
      final Uint8List bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${student.fullName.replaceAll(' ', '_')}_transcript.pdf',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to export PDF: $error')));
    }
  }

  static pw.Widget _header(StudentRecord student) {
    final contactPieces = [
      if (student.email != null) student.email!,
      if (student.phone != null) student.phone!,
      if (student.address != null) student.address!,
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Homeschool Transcript',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(student.fullName, style: pw.TextStyle(fontSize: 16)),
        pw.Text('Date of Birth: ${_formatDate(student.dateOfBirth)}'),
        pw.Text('Class of ${student.targetGradYear}'),
        if (contactPieces.isNotEmpty) pw.Text(contactPieces.join(' | ')),
      ],
    );
  }

  static pw.Widget _summary(TranscriptSnapshot snapshot) {
    final rows = [
      ['Weighted GPA', snapshot.weightedGpaString],
      ['Unweighted GPA', snapshot.unweightedGpaString],
      ['Credits Earned', snapshot.earnedCreditsString],
      ['Credits Attempted', snapshot.attemptedCreditsString],
    ];
    return pw.Table(
      border: pw.TableBorder.all(width: 0.3),
      children: rows
          .map(
            (row) => pw.TableRow(
              children: row
                  .map(
                    (value) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(value, style: pw.TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _yearSection(_AcademicYearGroup group) {
    final unweighted = TranscriptCalculator.gpaFor(group.enrollments);
    final weighted = TranscriptCalculator.gpaFor(
      group.enrollments,
      weighted: true,
    );
    final credits = group.enrollments.fold<double>(
      0,
      (sum, e) => sum + e.creditHours,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${group.yearLabel} | ${group.gradeLevel.label}',
            style: _subSectionTitle,
          ),
          pw.Text(
            'GPA ${unweighted.toStringAsFixed(2)} | Weighted ${weighted.toStringAsFixed(2)} | ${credits.toStringAsFixed(1)} credits',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder(horizontalInside: pw.BorderSide(width: 0.2)),
            columnWidths: {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: pdf.PdfColors.grey200,
                ),
                children: [
                  _tableHeaderCell('Course'),
                  _tableHeaderCell('Category'),
                  _tableHeaderCell('Grade'),
                  _tableHeaderCell('Credits'),
                  _tableHeaderCell('Weighted'),
                ],
              ),
              ...group.enrollments.map(_enrollmentRow),
            ],
          ),
        ],
      ),
    );
  }

  static pw.TableRow _enrollmentRow(Enrollment enrollment) {
    return pw.TableRow(
      children: [
        _tableCell(enrollment.courseTitle),
        _tableCell(enrollment.subjectCategory),
        _tableCell(enrollment.gradeLetter),
        _tableCell(enrollment.creditHours.toStringAsFixed(1)),
        _tableCell(enrollment.isWeighted ? 'Yes' : 'No'),
      ],
    );
  }

  static pw.Widget _awardsSection(List<Award> awards) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: awards
          .map(
            (award) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                '- ${award.name} | ${award.organization} | Grade ${award.gradeLevel} (${award.yearLabel})',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _activitiesSection(List<Activity> activities) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: activities
          .map(
            (activity) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                '- ${activity.title} (${activity.type}) | ${activity.organization} | ${activity.hours.toStringAsFixed(0)} hours | Grade ${activity.gradeLevel}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static final pw.TextStyle _sectionTitle = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
  );
  static final pw.TextStyle _subSectionTitle = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  );
}

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
  double? get gradePoints => _gradePointTable[gradeLetter.toUpperCase()];
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
}

class SampleData {
  static List<StudentRecord> get students => [
    StudentRecord(
      id: '1234',
      firstName: 'John',
      lastName: 'Smith',
      dateOfBirth: DateTime(2007, 4, 11),
      targetGradYear: 2025,
      email: 'john@example.com',
      phone: '555-0101',
      enrollments: [
        Enrollment(
          id: 'e1',
          studentId: '1234',
          gradeLevel: GradeLevel.grade9,
          yearLabel: '2023-2024',
          courseTitle: 'Algebra 1',
          subjectCategory: 'Math',
          description:
              'Basic algebraic concepts including real numbers and expressions.',
          creditHours: 1,
          gradeLetter: 'A',
        ),
        Enrollment(
          id: 'e2',
          studentId: '1234',
          gradeLevel: GradeLevel.grade9,
          yearLabel: '2023-2024',
          courseTitle: 'Biology',
          subjectCategory: 'Science Lab',
          description:
              'The study of life covering topics from cellular structure to ecosystems.',
          creditHours: 1,
          gradeLetter: 'A',
        ),
        Enrollment(
          id: 'e3',
          studentId: '1234',
          gradeLevel: GradeLevel.grade10,
          yearLabel: '2024-2025',
          courseTitle: 'Astronomy',
          subjectCategory: 'Science',
          description:
              'Study of cosmic phenomena and exploration of the solar system.',
          creditHours: 0.5,
          gradeLetter: 'A',
          isWeighted: true,
          weightMultiplier: 1.05,
        ),
      ],
      awards: [
        Award(
          id: 'a1',
          studentId: '1234',
          name: 'Teen Volunteer of the Month',
          description: 'Outstanding service to Loudoun Volunteers.',
          organization: 'Loudoun Volunteers',
          category: 'Other',
          yearLabel: '2023-2024',
          gradeLevel: 9,
        ),
        Award(
          id: 'a2',
          studentId: '1234',
          name: 'Blue Ribbon for Watercolor Landscape',
          description: 'Best overall artist in age group.',
          organization: 'Loudoun Arts',
          category: 'Fine Arts',
          yearLabel: '2024-2025',
          gradeLevel: 10,
        ),
      ],
      activities: [
        Activity(
          id: 'act1',
          studentId: '1234',
          type: 'Camp',
          title: 'Coding Camp for Teens',
          description:
              'Exploratory environment covering Python and Java basics.',
          organization: 'Loudoun Coders',
          hours: 20,
          yearLabel: '2023-2024',
          gradeLevel: 9,
        ),
        Activity(
          id: 'act2',
          studentId: '1234',
          type: 'Volunteer',
          title: 'Food Bank Shelf Stocker',
          description: 'Support sorting and restocking donated food.',
          organization: 'Loudoun Food Bank',
          hours: 20,
          yearLabel: '2024-2025',
          gradeLevel: 10,
        ),
      ],
    ),
    StudentRecord(
      id: '1235',
      firstName: 'Jane',
      lastName: 'Smith',
      dateOfBirth: DateTime(2008, 2, 5),
      targetGradYear: 2026,
      email: 'jane@example.com',
      enrollments: [
        Enrollment(
          id: 'e4',
          studentId: '1235',
          gradeLevel: GradeLevel.grade9,
          yearLabel: '2023-2024',
          courseTitle: 'Algebra 1',
          subjectCategory: 'Math',
          description:
              'Basic algebraic concepts including real numbers and expressions.',
          creditHours: 1,
          gradeLetter: 'A',
        ),
        Enrollment(
          id: 'e5',
          studentId: '1235',
          gradeLevel: GradeLevel.grade9,
          yearLabel: '2023-2024',
          courseTitle: 'Biology',
          subjectCategory: 'Science Lab',
          description:
              'Study of life from molecular level to entire ecosystems.',
          creditHours: 1,
          gradeLetter: 'A',
        ),
        Enrollment(
          id: 'e6',
          studentId: '1235',
          gradeLevel: GradeLevel.grade10,
          yearLabel: '2024-2025',
          courseTitle: 'Astronomy',
          subjectCategory: 'Science',
          description: 'Examining cosmic phenomena and stellar evolution.',
          creditHours: 0.5,
          gradeLetter: 'A',
        ),
      ],
      awards: [
        Award(
          id: 'a3',
          studentId: '1235',
          name: 'Teen Volunteer of the Month',
          description:
              'Recognizes leadership and service for Loudoun Volunteers.',
          organization: 'Loudoun Volunteers',
          category: 'Other',
          yearLabel: '2023-2024',
          gradeLevel: 9,
        ),
        Award(
          id: 'a4',
          studentId: '1235',
          name: 'Blue Ribbon for Watercolor Landscape',
          description: 'Top recognition at Loudoun Arts showcase.',
          organization: 'Loudoun Arts',
          category: 'Fine Arts',
          yearLabel: '2024-2025',
          gradeLevel: 10,
        ),
      ],
      activities: [
        Activity(
          id: 'act3',
          studentId: '1235',
          type: 'Camp',
          title: 'Coding Camp for Teens',
          description: 'Intro to collaborative coding and project work.',
          organization: 'Loudoun Coders',
          hours: 26,
          yearLabel: '2023-2024',
          gradeLevel: 9,
        ),
        Activity(
          id: 'act4',
          studentId: '1235',
          type: 'Volunteer',
          title: 'Food Bank Shelf Stocker',
          description: 'Weekly stocking support for community pantry.',
          organization: 'Loudoun Food Bank',
          hours: 28.2,
          yearLabel: '2024-2025',
          gradeLevel: 10,
        ),
        Activity(
          id: 'act5',
          studentId: '1235',
          type: 'Theater',
          title: 'The Lion, The Witch and The Wardrobe',
          description: 'Collaborative performance with Not Just Dance.',
          organization: 'Not Just Dance',
          hours: 32.6,
          yearLabel: '2024-2025',
          gradeLevel: 10,
        ),
      ],
    ),
  ];
}

class _AcademicYearGroup {
  _AcademicYearGroup(this.gradeLevel, this.yearLabel, this.enrollments);

  final GradeLevel gradeLevel;
  final String yearLabel;
  final List<Enrollment> enrollments;
}

List<_AcademicYearGroup> _groupEnrollments(List<Enrollment> enrollments) {
  final Map<String, List<Enrollment>> byKey = {};
  for (final enrollment in enrollments) {
    final key =
        '${enrollment.gradeLevel.value}|${enrollment.yearLabel.trim().toLowerCase()}';
    byKey.putIfAbsent(key, () => []).add(enrollment);
  }
  final groups = byKey.entries.map((entry) {
    final groupEnrollments = entry.value
      ..sort((a, b) => a.courseTitle.compareTo(b.courseTitle));
    final first = groupEnrollments.first;
    return _AcademicYearGroup(
      first.gradeLevel,
      first.yearLabel,
      List.unmodifiable(groupEnrollments),
    );
  }).toList();
  groups.sort((a, b) {
    final gradeCompare =
        a.gradeLevel.value.compareTo(b.gradeLevel.value);
    if (gradeCompare != 0) {
      return gradeCompare;
    }
    final yearCompare =
        _yearSortKey(a.yearLabel).compareTo(_yearSortKey(b.yearLabel));
    if (yearCompare != 0) {
      return yearCompare;
    }
    return a.yearLabel.compareTo(b.yearLabel);
  });
  return groups;
}

int _yearSortKey(String label) {
  final match = RegExp(r'(19|20)\d{2}').firstMatch(label);
  if (match != null) {
    return int.tryParse(match.group(0)!) ?? 0;
  }
  return 0;
}

final Map<String, double> _gradePointTable = {
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

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}
