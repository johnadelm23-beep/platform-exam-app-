import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:platformexamapp/features/auth/data/auth_repo.dart';
import 'package:platformexamapp/features/auth/data/model/user_data.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  UserData? userData;

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

  Future<void> getUserData() async {
    emit(GetUserDataLoadingState());

    final response = await AuthRepo.getUserData();

    if (response != null) {
      userData = response;
      emit(GetUserDataSuccessState());
    } else {
      emit(GetUserDataErrorState());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoadingState());

    try {
      final response = await AuthRepo.login(email: email, password: password);

      if (response) {
        await getUserData();
        emit(AuthSuccessState());
      } else {
        emit(AuthErrorState(errorMessage: "Login failed"));
      }
    } catch (e) {
      emit(AuthErrorState(errorMessage: e.toString()));
    }
  }
}
