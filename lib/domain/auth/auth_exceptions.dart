/// Typed exceptions thrown by [AuthenticationService].
///
/// Using typed exceptions instead of raw strings means callers can pattern-
/// match precisely and the UI can display the right localised message.
library;

/// Thrown when a registration identifier (email/phone) is already in use.
class IdentifierAlreadyExistsException implements Exception {
  const IdentifierAlreadyExistsException(this.identifier);
  final String identifier;

  @override
  String toString() =>
      'IdentifierAlreadyExistsException: "$identifier" is already registered.';
}

/// Thrown when login credentials do not match any stored account.
///
/// The message deliberately does not reveal which field was wrong to
/// prevent identifier enumeration attacks (Requirement 2.4).
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException: credentials did not match.';
}

/// Thrown when the local SQLite database or secure storage is unavailable.
class StorageUnavailableException implements Exception {
  const StorageUnavailableException([this.cause]);
  final Object? cause;

  @override
  String toString() => 'StorageUnavailableException: $cause';
}

/// Thrown when an operation requires an active session but none exists.
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();

  @override
  String toString() => 'NotAuthenticatedException: no active session.';
}
