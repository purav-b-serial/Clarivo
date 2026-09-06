import '../../data/database/app_database.dart';

/// Represents the current authentication state of the app.
///
/// The router listens to [AuthStateNotifier] which emits one of these states
/// and redirects accordingly:
///   - [AuthState.unauthenticated] → redirect to /login
///   - [AuthState.authenticated]  → allow access to /home/*
sealed class AuthState {
  const AuthState();
}

/// No active session — user must log in.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Active session with a loaded account row.
final class Authenticated extends AuthState {
  const Authenticated(this.account);
  final Account account;
}

/// Session is being restored on app startup (transient).
final class AuthLoading extends AuthState {
  const AuthLoading();
}
