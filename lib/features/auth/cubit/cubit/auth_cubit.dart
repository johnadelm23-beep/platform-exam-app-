import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:platformexamapp/features/auth/data/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> register(
    String email,
    String password,
    String name,
    String comfirmPassword,
  ) async {
    emit(AuthLoadingState());

    try {
      final response = await AuthRepo.register(
        email: email,
        password: password,
        name: name,
        comfirmPassword: comfirmPassword,
      );

      if (response) {
        emit(AuthSuccessState());
      } else {
        emit(AuthErrorState(errorMessage: "Registration failed"));
      }
    } catch (e) {
      emit(AuthErrorState(errorMessage: e.toString()));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoadingState());

    try {
      final response = await AuthRepo.login(email: email, password: password);

      if (response) {
        emit(AuthSuccessState());
      } else {
        emit(AuthErrorState(errorMessage: "Registration failed"));
      }
    } catch (e) {
      emit(AuthErrorState(errorMessage: e.toString()));
    }
  }
}
