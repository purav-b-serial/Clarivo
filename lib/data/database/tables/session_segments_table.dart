import 'package:drift/drift.dart';

/// Records time spent in content sections within an app session.
///
/// A segment starts when the student navigates to a section and ends when
/// they leave, the app is backgrounded, or the session is closed.
/// Segments with [endedAt] == NULL were interrupted (e.g. force-quit) and
/// are closed on the next app launch using the last heartbeat timestamp.
class SessionSegments extends Table {
  /// UUID v4.
  TextColumn get id => text()();

  /// Owning account.
  TextColumn get accountId => text()();

  /// Groups segments within the same app session.
  TextColumn get sessionId => text()();

  /// Content section identifier, if the student was in a specific section.
  TextColumn get sectionId => text().nullable()();

  /// Parent content package of the section, if applicable.
  TextColumn get packageId => text().nullable()();

  /// Unix timestamp in milliseconds when the segment started.
  IntColumn get startedAt => integer()();

  /// Unix timestamp in milliseconds when the segment ended. NULL if still open.
  IntColumn get endedAt => integer().nullable()();

  /// Duration in milliseconds. Populated when [endedAt] is set.
  /// The Progress_Tracker total-time invariant is: SUM(durationMs) == totalStudyTime.
  IntColumn get durationMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
