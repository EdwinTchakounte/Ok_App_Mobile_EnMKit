import 'package:enmkit/models/users_model.dart';
import 'package:enmkit/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enmkit/repositories/auth_repository.dart';

/// État de l'authentification
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({this.isLoading = false, this.user, this.error});
}

/// ViewModel
class AuthVM extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthVM(this._authRepository) : super(AuthState());

  /// Login
  Future<void> login(String phone, String password) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authRepository.login(phone, password);

      if (user != null) {
        state = AuthState(user: user); // succès
      } else {
        state = AuthState(error: 'Numéro ou mot de passe incorrect');
      }
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// Déconnexion
  void logout() {
    state = AuthState(); // réinitialise l'état
  }
}

/// Provider global
final authProvider = StateNotifierProvider<AuthVM, AuthState>(
  (ref) => AuthVM(ref.read(authRepositoryProvider)),
);
