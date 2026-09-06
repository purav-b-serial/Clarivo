import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_providers.dart';
import 'auth_exceptions.dart';
import 'auth_state.dart';

// ---------------------------------------------------------------------------
// Password hashing helper (PBKDF2-SHA256, pure Dart / web-safe)
// ---------------------------------------------------------------------------

class _PasswordHasher {
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static final _rng = Random.secure();

  /// Hashes [password] with a fresh random salt.
  /// Returns a "$salt:$hash" string where both parts are base64url-encoded.
  static Future<String> hash(String password) async {
    final salt = Uint8List(32);
    for (var i = 0; i < salt.length; i++) {
      salt[i] = _rng.nextInt(256);
    }
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();
    final saltB64 = base64Url.encode(salt);
    final hashB64 = base64Url.encode(hashBytes);
    return '$saltB64:$hashB64';
  }

  /// Verifies [password] against a stored "$salt:$hash" string.
  static Future<bool> verify(String password, String stored) async {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = base64Url.decode(parts[0]);
    final expectedHash = parts[1];
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();
    final actualHash = base64Url.encode(hashBytes);
    return actualHash == expectedHash;
  }
}

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class AuthenticationService {
  /// Registers a new account. Throws [IdentifierAlreadyExistsException] if
  /// the identifier is already taken, [StorageUnavailableException] on DB error.
  Future<Account> register({
    required String identifier,
    required String password,
    String? displayName,
  });

  /// Authenticates the user. Throws [InvalidCredentialsException] on mismatch.
  Future<Account> login({
    required String identifier,
    required String password,
  });

  /// Ends the active session and clears the secure session token.
  Future<void> logout();

  /// Returns the account row for a session token stored in secure storage,
  /// or null if no valid session exists.
  Future<Account?> restoreSession();

  /// Deletes all data for [accountId] — progress, uploads, notifications, etc.
  Future<void> deleteAccount(String accountId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class AuthenticationServiceImpl implements AuthenticationService {
  AuthenticationServiceImpl({
    required AppDatabase db,
    required FlutterSecureStorage secureStorage,
  })  : _db = db,
        _secure = secureStorage;

  final AppDatabase _db;
  final FlutterSecureStorage _secure;
  final _uuid = const Uuid();

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Validates email (RFC-5321 simplified) or E.164 phone.
  static bool isValidIdentifier(String id) {
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phoneRe = RegExp(r'^\+?[0-9]{7,15}$');
    return emailRe.hasMatch(id) || phoneRe.hasMatch(id);
  }

  String _sessionTokenKey(String accountId) =>
      '$kSessionTokenPrefix$accountId';

  // ── Register ─────────────────────────────────────────────────────────────

  @override
  Future<Account> register({
    required String identifier,
    required String password,
    String? displayName,
  }) async {
    // Check for duplicate identifier.
    final existing = await (_db.select(_db.accounts)
          ..where((a) => a.identifier.equals(identifier)))
        .getSingleOrNull();
    if (existing != null) {
      throw IdentifierAlreadyExistsException(identifier);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();

    // PBKDF2-SHA256 hash — async, pure Dart, works on web.
    final hash = await _PasswordHasher.hash(password);

    final companion = AccountsCompanion.insert(
      id: id,
      identifier: identifier,
      passwordHash: hash,
      displayName: Value(displayName),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _db.into(_db.accounts).insert(companion);
    } catch (e) {
      throw StorageUnavailableException(e);
    }

    // Create and persist session token.
    final token = _uuid.v4();
    await _secure.write(key: _sessionTokenKey(id), value: token);

    return (_db.select(_db.accounts)..where((a) => a.id.equals(id)))
        .getSingle();
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  @override
  Future<Account> login({
    required String identifier,
    required String password,
  }) async {
    final account = await (_db.select(_db.accounts)
          ..where((a) => a.identifier.equals(identifier)))
        .getSingleOrNull();

    if (account == null) throw const InvalidCredentialsException();

    // PBKDF2-SHA256 verification — deliberately vague: don't reveal which field was wrong.
    final valid = await _PasswordHasher.verify(password, account.passwordHash);
    if (!valid) throw const InvalidCredentialsException();

    // Rotate session token on every login.
    final token = _uuid.v4();
    await _secure.write(key: _sessionTokenKey(account.id), value: token);

    return account;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    // We don't know which account is active here — the caller (AuthStateNotifier)
    // passes the accountId via deleteAll or we delete the token for the current id.
    // Secure storage is cleared by the notifier which holds the account id.
  }

  /// Clears the session token for a specific account (called by notifier).
  Future<void> clearSessionToken(String accountId) async {
    await _secure.delete(key: _sessionTokenKey(accountId));
  }

  // ── Restore session ───────────────────────────────────────────────────────

  @override
  Future<Account?> restoreSession() async {
    // Scan all accounts and check if any has a valid token in secure storage.
    final accounts = await _db.select(_db.accounts).get();
    for (final account in accounts) {
      final token =
          await _secure.read(key: _sessionTokenKey(account.id));
      if (token != null && token.isNotEmpty) {
        return account;
      }
    }
    return null;
  }

  // ── Delete account ────────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount(String accountId) async {
    // Clear secure storage token first.
    await _secure.delete(key: _sessionTokenKey(accountId));

    // Cascade-delete all account data. The DB foreign keys handle related
    // rows in supervisor_relationships. We manually clear other tables
    // scoped by accountId.
    await _db.transaction(() async {
      await (_db.delete(_db.tutorInteractions)
            ..where((t) => t.accountId.equals(accountId)))
          .go();
      await (_db.delete(_db.sessionSegments)
            ..where((s) => s.accountId.equals(accountId)))
          .go();
      await (_db.delete(_db.notificationSchedules)
            ..where((n) => n.accountId.equals(accountId)))
          .go();
      await (_db.delete(_db.documents)
            ..where((d) => d.accountId.equals(accountId)))
          .go();
      await (_db.delete(_db.accounts)
            ..where((a) => a.id.equals(accountId)))
          .go();
    });
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationServiceImpl(
    db: ref.watch(appDatabaseProvider),
    secureStorage: const FlutterSecureStorage(),
  );
});
