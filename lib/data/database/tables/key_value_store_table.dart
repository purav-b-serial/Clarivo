import 'package:drift/drift.dart';

/// Simple key-value store for app-wide settings that don't warrant their own table.
///
/// Examples of stored keys:
///   - [kKvKeyLocale]         — active UI locale code ('en', 'hi', etc.)
///   - [kKvKeyLastHeartbeat]  — Unix ms timestamp for session crash recovery
///
/// Values are stored as strings; the caller is responsible for serialising
/// and deserialising typed values.
class KeyValueStore extends Table {
  /// Unique string key.
  TextColumn get key => text()();

  /// Serialised string value.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
