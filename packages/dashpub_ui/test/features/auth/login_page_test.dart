import 'package:bloc_test/bloc_test.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/src/features/auth/auth_bloc.dart';
import 'package:dashpub_ui/src/features/auth/auth_pages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class MockDashpubApiClient extends Mock implements DashpubApiClient {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('LoginPage', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.state).thenReturn(Unauthenticated());
    });

    Widget createWidgetUnderTest() {
      return ShadcnApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const LoginPage(),
        ),
      );
    }

    testWidgets('renders login form', (tester) async {
      // Set a larger surface size to prevent layout overflow in shadcn components
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());

      // Use findsWidgets or findsNWidgets because 'Login' appears in title and button
      expect(find.text('Login'), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      // Specify the button explicitly
      expect(find.widgetWithText(Button, 'Login'), findsOneWidget);
    });

    testWidgets('adds LoginRequested event when login button is pressed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuthBloc.state).thenReturn(Unauthenticated());
      await tester.pumpWidget(createWidgetUnderTest());

      // Find the text fields.
      await tester.enterText(
        find.widgetWithText(TextField, 'm@example.com'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '••••••••'),
        'password',
      );

      await tester.tap(find.widgetWithText(Button, 'Login'));
      await tester.pump();

      verify(
        () => mockAuthBloc.add(LoginRequested('test@example.com', 'password')),
      ).called(1);
    });
  });
}
