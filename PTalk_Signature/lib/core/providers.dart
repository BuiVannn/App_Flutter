import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';

/// Lưu trữ token an toàn (Keychain/Keystore).
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Dịch vụ SSO Authentik.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Đã đăng nhập chưa (đọc từ TokenStore) — dùng cho Splash điều hướng.
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return ref.read(tokenStoreProvider).isLoggedIn();
});

/// Trạng thái thao tác đăng nhập trên màn Login.
sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {
  const LoginIdle();
}

class LoginInProgress extends LoginState {
  const LoginInProgress();
}

class LoginSuccess extends LoginState {
  final AuthResult result;
  const LoginSuccess(this.result);
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._auth, this._store) : super(const LoginIdle());

  final AuthService _auth;
  final TokenStore _store;

  Future<bool> loginWithSso() async {
    state = const LoginInProgress();
    try {
      final result = await _auth.login();
      await _store.saveFromAuthResult(result);
      state = LoginSuccess(result);
      return true;
    } on AuthException catch (e) {
      state = LoginFailure(e.message);
      return false;
    } catch (e) {
      state = LoginFailure('Lỗi không xác định: $e');
      return false;
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(
    ref.read(authServiceProvider),
    ref.read(tokenStoreProvider),
  );
});
