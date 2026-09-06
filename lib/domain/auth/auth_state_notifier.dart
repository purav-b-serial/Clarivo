import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import 'auth_exceptions.dart';
import 'auth_state.dart';
import 'authentication_service.dart';

// ---------------------------------------------------------------------------
// AuthStateNotifier — Task 3.2
// ---------------------------------------------------------------------------

/// Manages the global authentication state and exposes it as a [Notifier].
///
/// The router watches [authStateProvider] and redirects users based on the
/// current [AuthState]. On app startup, [restoreSession] is called from
/// [main()] to replay any persisted session before the first frame.
class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthLoading();

  AuthenticationServiceImpl get _svc =>
      ref.read(authenticationServiceProvider) as AuthenticationServiceImpl;

  // ── Session restore (called at app startup) ────────────────────────────

  /// Attempts to restore a persisted session from flutter_secure_storage.
  /// Transitions to [Authenticated] if a valid token is found, else [Unauthenticated].
  Future<void> restoreSession() async {
    state = const AuthLoading();
    try {
      final account = await _svc.restoreSession();
      state = account != null
          ? Authenticated(account)
          : const Unauthenticated();
    } catch (_) {
      state = const Unauthenticated();
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  /// Registers a new account and immediately transitions to [Authenticated].
  ///
  /// Throws [IdentifierAlreadyExistsException] or [StorageUnavailableException]
  /// on failure — the UI catches these and shows the appropriate error message.
  Future<void> register({
    required String identifier,
    required String password,
    String? displayName,
  }) async {
    // End any existing session before creating a new account.
    if (state is Authenticated) {
      await _logout((state as Authenticated).account);
    }
    final account = await _svc.register(
      identifier: identifier,
      password: password,
      displayName: displayName,
    );
    state = Authenticated(account);
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Authenticates the user and transitions to [Authenticated].
  ///
  /// If another account is currently active, its session is ended first
  /// (Requirement 2.6 — multi-account switching).
  ///
  /// Throws [InvalidCredentialsException] on mismatch.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    // End existing session if a different account is active.
    if (state is Authenticated) {
      await _logout((state as Authenticated).account);
    }
    final account = await _svc.login(
      identifier: identifier,
      password: password,
    );
    state = Authenticated(account);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Ends the active session and returns to [Unauthenticated].
  Future<void> logout() async {
    if (state is Authenticated) {
      await _logout((state as Authenticated).account);
    }
    state = const Unauthenticated();
  }

  Future<void> _logout(Account account) async {
    await _svc.clearSessionToken(account.id);
  }

  // ── Convenience getters ───────────────────────────────────────────────────

  /// The currently authenticated account, or null.
  Account? get currentAccount =>
      state is Authenticated ? (state as Authenticated).account : null;

  /// True when a session is active.
  bool get isAuthenticated => state is Authenticated;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// The global auth state notifier. Watched by the router for redirect logic.
final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

/// Convenience provider that returns the current [Account] or null.
final currentAccountProvider = Provider<Account?>((ref) {
  final state = ref.watch(authStateProvider);
  return state is Authenticated ? state.account : null;
});
