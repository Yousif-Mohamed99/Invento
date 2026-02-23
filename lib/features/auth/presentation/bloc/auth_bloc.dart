import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/auth/domain/usecase/login_usecase.dart';
import 'package:invento/features/auth/domain/usecase/register_usecase.dart';
import 'package:invento/features/auth/domain/usecase/reset_password_usecase.dart';
import 'package:invento/features/auth/domain/usecase/google_sign_in_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final GoogleSignInUseCase googleSignInUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.resetPasswordUseCase,
    required this.googleSignInUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final credential = await loginUseCase(event.email, event.password);
        emit(AuthSuccess(credential.user!.uid));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final credential = await registerUseCase(
          email: event.email,
          password: event.password,
          storeName: event.storeName,
          city: event.city,
          address: event.address,
        );
        emit(AuthSuccess(credential.user!.uid));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await loginUseCase.repository.signOut();
        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<ResetPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await resetPasswordUseCase(event.email);
        emit(
          AuthPasswordResetSuccess(
            "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني",
          ),
        );
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<GoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final credential = await googleSignInUseCase();
        emit(AuthSuccess(credential.user!.uid));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
