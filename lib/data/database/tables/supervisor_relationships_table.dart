import 'package:drift/drift.dart';
import 'accounts_table.dart';

/// One-to-one relationship between a student account and a supervisor PIN.
///
/// A student may have at most one supervisor. The PIN is bcrypt-hashed
/// (cost 12) before storage — the raw PIN is never persisted.
class SupervisorRelationships extends Table {
  /// UUID v4.
  TextColumn get id => text()();

  /// References [Accounts.id] for the student who granted supervisor access.
  TextColumn get studentId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// bcrypt hash (cost 12) of the supervisor's 4–6 digit PIN.
  TextColumn get supervisorPinHash => text()();

  /// Unix timestamp in milliseconds when access was granted.
  IntColumn get grantedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {studentId},
      ];
}
