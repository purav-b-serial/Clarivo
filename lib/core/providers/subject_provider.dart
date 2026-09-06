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

const List<CbseSubject> kCbseSubjects = [
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

// ---------------------------------------------------------------------------
// Dynamic: classes that actually have content in the database
// ---------------------------------------------------------------------------

/// Async provider that queries the DB for which class numbers have content.
/// Class numbers are stored as a prefix in the chapter name (e.g. "Class 10 — …")
/// For our current dataset, Class 10 is the only class with notes.
/// As more class content is added to the JSON files, they will appear automatically.
final availableClassesProvider =
    FutureProvider<List<CbseClass>>((ref) async {
  final db = ref.watch(demoDatabaseProvider);

  // Get all distinct subject names in DB — if ANY subject has content,
  // we know Class 10 is available (current dataset is all Class 10).
  // When content for other classes is added, the chapter names will include
  // the class number so we can filter dynamically.
  final subjects = await db.getSubjects();

  if (subjects.isEmpty) {
    // No content yet — return empty list so UI shows "loading" state.
    return [];
  }

  // For now our content is all Class 10.
  // When Class 6-9, 11, 12 content is added, add detection logic here.
  // Detection: query chapters that start with "Class X" prefix.
  return [const CbseClass(number: 10, label: 'Class 10')];
});

// ---------------------------------------------------------------------------
// Study context: selected class + selected subject
// ---------------------------------------------------------------------------

class StudyContext {
  const StudyContext({this.selectedClass, this.selectedSubject});
  final int? selectedClass;
  final String? selectedSubject;

  StudyContext copyWith({int? selectedClass, String? selectedSubject}) =>
      StudyContext(
        selectedClass: selectedClass ?? this.selectedClass,
        selectedSubject: selectedSubject ?? this.selectedSubject,
      );

  bool get hasClass => selectedClass != null;
  bool get hasSubject => selectedSubject != null;
  bool get isComplete => hasClass && hasSubject;

  String get contextLabel {
    if (isComplete) return 'Class $selectedClass — $selectedSubject';
    if (hasClass) return 'Class $selectedClass';
    return 'No class selected';
  }
}

class StudyContextNotifier extends Notifier<StudyContext> {
  @override
  StudyContext build() => const StudyContext();

  void selectClass(int classNumber) {
    // Clear subject when class changes so student must re-pick
    state = StudyContext(selectedClass: classNumber);
  }

  void selectSubject(String subject) {
    state = state.copyWith(selectedSubject: subject);
  }

  void clearSubject() {
    // Go back to subject picker, keep class
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
  try {
    return kCbseSubjects.firstWhere((s) => s.name == name);
  } catch (_) {
    return null;
  }
});
