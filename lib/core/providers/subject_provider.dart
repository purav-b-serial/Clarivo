import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/demo_database.dart';

// ---------------------------------------------------------------------------
// CBSE Class model
// ---------------------------------------------------------------------------

class CbseClass {
  const CbseClass({required this.number, required this.label});
  final int number;
  final String label;
}

// All possible CBSE classes — UI only shows ones that have content in DB.
const List<CbseClass> kAllCbseClasses = [
  CbseClass(number: 6,  label: 'Class 6'),
  CbseClass(number: 7,  label: 'Class 7'),
  CbseClass(number: 8,  label: 'Class 8'),
  CbseClass(number: 9,  label: 'Class 9'),
  CbseClass(number: 10, label: 'Class 10'),
  CbseClass(number: 11, label: 'Class 11'),
  CbseClass(number: 12, label: 'Class 12'),
];

// ---------------------------------------------------------------------------
// CBSE Subject model
// ---------------------------------------------------------------------------

class CbseSubject {
  const CbseSubject({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
  final String name;
  final IconData icon;
  final Color color;
  final String description;
}

// ---------------------------------------------------------------------------
// Per-class subject catalogues.
// A subject listed here only becomes selectable once it has notes in the DB
// (see availableSubjectsProvider); otherwise it shows as "coming soon".
// ---------------------------------------------------------------------------

const List<CbseSubject> kClass10Subjects = [
  CbseSubject(
    name: 'Science',
    icon: Icons.science_outlined,
    color: Color(0xFF1565C0),
    description: 'Physics, Chemistry, Biology',
  ),
  CbseSubject(
    name: 'Mathematics',
    icon: Icons.calculate_outlined,
    color: Color(0xFF6A1B9A),
    description: 'Algebra, Geometry, Trigonometry, Statistics',
  ),
  CbseSubject(
    name: 'Social Science',
    icon: Icons.public_outlined,
    color: Color(0xFF2E7D32),
    description: 'History, Geography, Civics, Economics',
  ),
  CbseSubject(
    name: 'English',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFC62828),
    description: 'Literature, Grammar, Writing',
  ),
  CbseSubject(
    name: 'Hindi',
    icon: Icons.translate_outlined,
    color: Color(0xFFE65100),
    description: 'Kshitij, Kritika, Vyakaran',
  ),
  CbseSubject(
    name: 'Sanskrit',
    icon: Icons.auto_stories_outlined,
    color: Color(0xFF00695C),
    description: 'Shemushi, Vyakaranavithi',
  ),
];

const List<CbseSubject> kClass12Subjects = [
  CbseSubject(
    name: 'Physics',
    icon: Icons.bolt_outlined,
    color: Color(0xFF1565C0),
    description: 'Electrostatics, Current, Optics, Modern Physics',
  ),
  CbseSubject(
    name: 'Chemistry',
    icon: Icons.science_outlined,
    color: Color(0xFF6A1B9A),
    description: 'Physical, Organic, Inorganic Chemistry',
  ),
  CbseSubject(
    name: 'Mathematics',
    icon: Icons.calculate_outlined,
    color: Color(0xFF283593),
    description: 'Calculus, Algebra, Vectors, Probability',
  ),
  CbseSubject(
    name: 'Biology',
    icon: Icons.biotech_outlined,
    color: Color(0xFF2E7D32),
    description: 'Genetics, Ecology, Human Physiology',
  ),
  CbseSubject(
    name: 'English',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFC62828),
    description: 'Flamingo, Vistas, Writing Skills',
  ),
  CbseSubject(
    name: 'Computer Science',
    icon: Icons.computer_outlined,
    color: Color(0xFF00695C),
    description: 'Python, Data Structures, SQL, Networking',
  ),
];

// Class 11 — Science stream. Same six science-stream subjects as Class 12.
const List<CbseSubject> kClass11Subjects = [
  CbseSubject(
    name: 'Physics',
    icon: Icons.bolt_outlined,
    color: Color(0xFF1565C0),
    description: 'Kinematics, Laws of Motion, Thermodynamics, Waves',
  ),
  CbseSubject(
    name: 'Chemistry',
    icon: Icons.science_outlined,
    color: Color(0xFF6A1B9A),
    description: 'Atomic Structure, Bonding, Equilibrium, Organic Basics',
  ),
  CbseSubject(
    name: 'Mathematics',
    icon: Icons.calculate_outlined,
    color: Color(0xFF283593),
    description: 'Sets, Trigonometry, Sequences, Conic Sections, Calculus',
  ),
  CbseSubject(
    name: 'Biology',
    icon: Icons.biotech_outlined,
    color: Color(0xFF2E7D32),
    description: 'Diversity, Cell, Plant & Human Physiology',
  ),
  CbseSubject(
    name: 'English',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFC62828),
    description: 'Hornbill, Snapshots, Writing Skills',
  ),
  CbseSubject(
    name: 'Computer Science',
    icon: Icons.computer_outlined,
    color: Color(0xFF00695C),
    description: 'Python, Data Handling, Boolean Logic, Networking',
  ),
];

/// Returns the full subject catalogue for a class (both available + coming soon).
List<CbseSubject> subjectsForClass(int classNumber) {
  switch (classNumber) {
    case 12:
      return kClass12Subjects;
    case 11:
      return kClass11Subjects;
    case 10:
    default:
      return kClass10Subjects;
  }
}

/// Legacy alias — defaults to the Class 10 catalogue.
const List<CbseSubject> kCbseSubjects = kClass10Subjects;

// ---------------------------------------------------------------------------
// Dynamic: classes that actually have content in the database
// ---------------------------------------------------------------------------

/// Async provider that queries the DB for which class numbers actually have
/// content, and returns them as [CbseClass] entries. New classes appear
/// automatically as soon as their notes are seeded — no code change needed.
final availableClassesProvider =
    FutureProvider<List<CbseClass>>((ref) async {
  final db = ref.watch(demoDatabaseProvider);
  final classNumbers = await db.getAvailableClasses();
  if (classNumbers.isEmpty) return [];

  return classNumbers
      .map((n) => CbseClass(number: n, label: 'Class $n'))
      .toList();
});

/// Represents a subject entry with whether notes are available for it yet.
class SubjectAvailability {
  const SubjectAvailability({required this.subject, required this.hasContent});
  final CbseSubject subject;
  final bool hasContent;
}

/// For the selected class, returns every subject in that class's catalogue
/// annotated with whether it currently has notes (hasContent). Subjects
/// without notes show as "coming soon" instead of being hidden.
final availableSubjectsProvider =
    FutureProvider.family<List<SubjectAvailability>, int>((ref, classNumber) async {
  final db = ref.watch(demoDatabaseProvider);
  final seeded = (await db.getSubjects(classNumber: classNumber)).toSet();
  final catalogue = subjectsForClass(classNumber);
  return catalogue
      .map((s) => SubjectAvailability(
            subject: s,
            hasContent: seeded.contains(s.name),
          ))
      .toList();
});

// ---------------------------------------------------------------------------
// Competitive exam prep modes (JEE / NEET)
// ---------------------------------------------------------------------------

/// A competitive-exam preparation mode. When active, Clara is auto-scoped to
/// multiple classes and multiple subjects at once (no single class/subject
/// selection needed), covering the whole exam syllabus.
class ExamPrep {
  const ExamPrep({
    required this.id,
    required this.name,
    required this.fullName,
    required this.classes,
    required this.subjects,
    required this.icon,
    required this.color,
    required this.description,
  });

  /// Short id, e.g. 'jee' or 'neet'.
  final String id;

  /// Short display name, e.g. 'JEE'.
  final String name;

  /// Full display name, e.g. 'JEE (Engineering)'.
  final String fullName;

  /// Classes covered — JEE/NEET span Class 11 and 12.
  final List<int> classes;

  /// Subjects covered simultaneously.
  final List<String> subjects;

  final IconData icon;
  final Color color;
  final String description;
}

/// The two supported competitive exams. JEE covers PCM, NEET covers PCB,
/// each across Class 11 and Class 12.
const List<ExamPrep> kExamPreps = [
  ExamPrep(
    id: 'jee',
    name: 'JEE',
    fullName: 'JEE (Engineering)',
    classes: [11, 12],
    subjects: ['Physics', 'Chemistry', 'Mathematics'],
    icon: Icons.engineering_outlined,
    color: Color(0xFF283593),
    description: 'Class 11 & 12 · Physics, Chemistry, Mathematics',
  ),
  ExamPrep(
    id: 'neet',
    name: 'NEET',
    fullName: 'NEET (Medical)',
    classes: [11, 12],
    subjects: ['Physics', 'Chemistry', 'Biology'],
    icon: Icons.medical_services_outlined,
    color: Color(0xFF2E7D32),
    description: 'Class 11 & 12 · Physics, Chemistry, Biology',
  ),
];

ExamPrep? examPrepById(String? id) {
  if (id == null) return null;
  for (final e in kExamPreps) {
    if (e.id == id) return e;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Study context: selected class + selected subject, OR an exam-prep mode
// ---------------------------------------------------------------------------

class StudyContext {
  const StudyContext({
    this.selectedClass,
    this.selectedSubject,
    this.examId,
  });
  final int? selectedClass;
  final String? selectedSubject;

  /// When set (e.g. 'jee'/'neet'), Clara is in competitive-exam mode and
  /// ignores single class/subject selection.
  final String? examId;

  StudyContext copyWith({int? selectedClass, String? selectedSubject}) =>
      StudyContext(
        selectedClass: selectedClass ?? this.selectedClass,
        selectedSubject: selectedSubject ?? this.selectedSubject,
        examId: examId,
      );

  bool get isExamMode => examId != null;
  ExamPrep? get exam => examPrepById(examId);

  bool get hasClass => selectedClass != null;
  bool get hasSubject => selectedSubject != null;
  bool get isComplete => hasClass && hasSubject;

  String get contextLabel {
    final e = exam;
    if (e != null) return e.fullName;
    if (isComplete) return 'Class $selectedClass — $selectedSubject';
    if (hasClass) return 'Class $selectedClass';
    return 'No class selected';
  }
}

class StudyContextNotifier extends Notifier<StudyContext> {
  @override
  StudyContext build() => const StudyContext();

  void selectClass(int classNumber) {
    // Clear subject and any exam mode when class changes so student re-picks
    state = StudyContext(selectedClass: classNumber);
  }

  void selectSubject(String subject) {
    state = state.copyWith(selectedSubject: subject);
  }

  /// Enter competitive-exam mode (JEE/NEET). Clears any single class/subject.
  void selectExam(String examId) {
    state = StudyContext(examId: examId);
  }

  void clearSubject() {
    // Go back to subject picker, keep class (exam mode has no subject step)
    state = StudyContext(selectedClass: state.selectedClass);
  }

  void clearAll() {
    state = const StudyContext();
  }
}

final studyContextProvider =
    NotifierProvider<StudyContextNotifier, StudyContext>(
        StudyContextNotifier.new);

// Legacy aliases so ClaraScreen and other existing code keep working
final activeSubjectProvider = Provider<String?>((ref) {
  return ref.watch(studyContextProvider).selectedSubject;
});

final activeSubjectInfoProvider = Provider<CbseSubject?>((ref) {
  final name = ref.watch(activeSubjectProvider);
  if (name == null) return null;

  // Prefer the catalogue for the currently selected class, then fall back to
  // searching ALL known subjects across every class. Without this, selecting a
  // Class 12 subject (e.g. Physics) returned null because only the Class 10
  // catalogue was searched — causing the header to show the subject while the
  // banner wrongly said "No subject selected".
  final selectedClass = ref.watch(studyContextProvider).selectedClass;

  final searchOrder = <CbseSubject>[
    if (selectedClass != null) ...subjectsForClass(selectedClass),
    ...kClass10Subjects,
    ...kClass12Subjects,
  ];

  for (final s in searchOrder) {
    if (s.name == name) return s;
  }
  return null;
});
