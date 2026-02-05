import 'package:bloc_test/bloc_test.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/src/features/auth/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDashpubApiClient extends Mock implements DashpubApiClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  group('AuthBloc', () {
    late MockDashpubApiClient mockApiClient;
    late AuthBloc authBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockApiClient = MockDashpubApiClient();
      authBloc = AuthBloc(mockApiClient);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthSystemNotInitialized] when system is not initialized',
      build: () {
        when(
          () => mockApiClient.isInitialized(),
        ).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [AuthSystemNotInitialized()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] when token is missing',
      build: () {
        when(() => mockApiClient.isInitialized()).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Authenticated] when login succeeds',
      build: () {
        final user = User(
          '1',
          false,
          'test@example.com',
          'Test User',
          'hash',
          [],
          'token',
        );
        final response = AuthResponse('token', user);

        when(
          () => mockApiClient.login(any(), any()),
        ).thenAnswer((_) async => response);
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested('email', 'password')),
      expect: () => [
        AuthLoading(),
        Authenticated(
          User(
            '1',
            false,
            'test@example.com',
            'Test User',
            'hash',
            [],
            'token',
          ),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthFailure] when login fails',
      build: () {
        when(
          () => mockApiClient.login(any(), any()),
        ).thenThrow(Exception('Login failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested('email', 'password')),
      expect: () => [AuthLoading(), AuthFailure('Exception: Login failed')],
    );
  });
}
