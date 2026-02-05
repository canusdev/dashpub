import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashpub_api/dashpub_api.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  RegisterRequested(this.email, this.password, this.name);
  @override
  List<Object?> get props => [email, password, name];
}

class LogoutRequested extends AuthEvent {}

class UpdateUser extends AuthEvent {
  final User user;
  UpdateUser(this.user);
  @override
  List<Object?> get props => [user];
}

// State
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthSystemNotInitialized extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DashpubApiClient apiClient;

  AuthBloc(this.apiClient) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateUser>(_onUpdateUser);
  }

  void _onUpdateUser(UpdateUser event, Emitter<AuthState> emit) {
    emit(Authenticated(event.user));
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      bool? initialized;
      int retries = 3;
      while (retries > 0) {
        try {
          initialized = await apiClient.isInitialized();
          break;
        } catch (_) {
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (initialized == false) {
        emit(AuthSystemNotInitialized());
        return;
      }
    } catch (_) {
      // Fallback if truly unreachable after retries
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      apiClient.setToken(token);
      try {
        final user = await apiClient.getMe();
        emit(Authenticated(user));
      } catch (e) {
        await prefs.remove('auth_token');
        apiClient.setToken(null);
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await apiClient.login(event.email, event.password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.token);
      apiClient.setToken(response.token);
      emit(Authenticated(response.user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await apiClient.register(
        event.email,
        event.password,
        event.name,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.token);
      apiClient.setToken(response.token);
      emit(Authenticated(response.user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    apiClient.setToken(null);
    emit(Unauthenticated());
  }
}
