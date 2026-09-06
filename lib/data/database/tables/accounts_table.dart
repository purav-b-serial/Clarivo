import 'package:drift/drift.dart';

/// Stores registered student accounts.
///
/// Credentials are never stored in plaintext — [passwordHash] is a bcrypt
/// hash (cost 12). The raw password is discarded immediately after hashing.
/// Session tokens are stored separately in flutter_secure_storage, never here.
class Accounts extends Table {
  /// UUID v4, generated at registration time.
  TextColumn get id => text()();

  /// Email address or E.164 phone number — unique across all accounts on device.
  TextColumn get identifier => text().unique()();

  /// bcrypt hash (cost 12) of the account password.
  TextColumn get passwordHash => text()();

  /// Optional display name shown in the UI.
  TextColumn get displayName => text().nullable()();

  /// Unix timestamp in milliseconds when the account was created.
  IntColumn get createdAt => integer()();

  /// Unix timestamp in milliseconds of the last update.
  IntColumn get updatedAt => integer()();

  /// BCP-47 language code for the preferred UI language (default: 'en').
  TextColumn get languageCode => text().withDefault(const Constant('en'))();

  @override
  Set<Column> get primaryKey => {id};
}
