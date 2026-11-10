import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/core/utils/password_hash.dart';

class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => currentUser != null;
  bool get isAdmin => currentUser?.role.toLowerCase() == 'admin';

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<bool> login(String username, String pinOrPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await (_db.select(_db.users)
            ..where((u) => u.username.equals(username.trim())))
          .getSingleOrNull();

      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User "$username" not found / उपयोगकर्ता नहीं मिला',
        );
        return false;
      }

      if (!verifyPassword(pinOrPassword, user.passwordHash)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Incorrect PIN or Password / गलत पिन या पासवर्ड',
        );
        return false;
      }

      state = state.copyWith(
        currentUser: user,
        isLoading: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: $e',
      );
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }

  Future<bool> createUser({
    required String username,
    required String pin,
    required String role,
    required String fullName,
  }) async {
    try {
      final existing = await (_db.select(_db.users)
            ..where((u) => u.username.equals(username.trim())))
          .getSingleOrNull();

      if (existing != null) {
        return false;
      }

      await _db.into(_db.users).insert(
        UsersCompanion.insert(
          username: username.trim(),
          passwordHash: hashPassword(pin),
          role: role,
          fullName: Value(fullName.trim()),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updatePassword(int userId, String newPin) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(hashPassword(newPin)),
      ),
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final allUsersStreamProvider = StreamProvider<List<User>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.users).watch();
});
