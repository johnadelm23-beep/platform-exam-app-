import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:platformexamapp/features/auth/data/auth_repo.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  UserData? userData;
  getUserData() async {
    emit(GetUserDataLoading());
    final user = await AuthRepo.getUserData();
    if (user != null) {
      userData = user;
      emit(GetUserDataSuccess());
    } else {
      emit(GetUserDaraError());
    }
  }
}
