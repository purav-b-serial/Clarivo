import 'package:drift/drift.dart';

/// Stores the notification schedule for each account.
///
/// Each row represents one recurring notification type per account.
/// [platformIds] holds the JSON-encoded list of platform-specific notification
/// IDs so they can be cancelled individually if the schedule is disabled.
class NotificationSchedules extends Table {
  /// UUID v4.
  TextColumn get id => text()();

  /// Owning account.
  TextColumn get accountId => text()();

  /// Notification type: 'study_reminder' | 'daily_tip'.
  TextColumn get type => text()();

  /// Scheduled delivery time in "HH:MM" 24-hour format.
  TextColumn get timeOfDay => text()();

  /// Whether delivery is currently active (1) or paused (0).
  IntColumn get enabled => integer().withDefault(const Constant(1))();

  /// JSON-encoded list of platform notification IDs (integers or strings
  /// depending on the platform). Used for cancellation.
  TextColumn get platformIds => text().nullable()();

  /// Unix timestamp in milliseconds when this schedule was created.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
