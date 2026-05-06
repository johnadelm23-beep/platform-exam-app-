import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:platformexamapp/features/auth/data/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await AuthRepo.login(email: email, password: password);
      if (response) {
        emit(AuthSuccess());
      } else {
        emit(AuthError(errorMessage: "Login Failed"));
      }
    } catch (e) {
      emit(AuthError(errorMessage: e.toString()));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AuthLoading());
    try {
      final response = await AuthRepo.register(
        email: email,
        password: password,
        name: name,
      );
      if (response) {
        emit(AuthSuccess());
      } else {
        emit(AuthError(errorMessage: "Faild Register"));
      }
    } catch (e) {
      emit(AuthError(errorMessage: e.toString()));
    }
  }

  signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final response = await AuthRepo.signInWithGoogle();
      if (response) {
        emit(AuthSuccess());
      } else {
        emit(AuthError(errorMessage: "Sign in Failed"));
      }
    } catch (e) {
      emit(AuthError(errorMessage: e.toString()));
    }
  }
}
