import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/password_repository.dart';
import '../../data/models/password_change_model.dart';

class PasswordChangeCubit extends Cubit<PasswordChangeState> {
  final PasswordRepository _passwordRepository;
  final String _token;

  PasswordChangeCubit(this._passwordRepository, this._token) : super(PasswordChangeInitial());

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(PasswordChangeLoading());

    try {
      final request = PasswordChangeRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      await _passwordRepository.changePassword(request, _token);
      emit(PasswordChangeSuccess());
    } catch (e) {
      emit(PasswordChangeError(e.toString()));
    }
  }

  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    emit(PasswordChangeLoading());

    try {
      final request = PasswordResetRequest(newPassword: newPassword);
      final resultPassword = await _passwordRepository.resetPassword(userId, request, _token);
      emit(PasswordResetSuccess(resultPassword));
    } catch (e) {
      emit(PasswordChangeError(e.toString()));
    }
  }

  void reset() {
    emit(PasswordChangeInitial());
  }
}

abstract class PasswordChangeState {}

class PasswordChangeInitial extends PasswordChangeState {}

class PasswordChangeLoading extends PasswordChangeState {}

class PasswordChangeSuccess extends PasswordChangeState {}

class PasswordResetSuccess extends PasswordChangeState {
  final String newPassword;

  PasswordResetSuccess(this.newPassword);
}

class PasswordChangeError extends PasswordChangeState {
  final String message;

  PasswordChangeError(this.message);
}
