import 'dart:ui';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDashpubApiClient extends Mock implements DashpubApiClient {}

void main() {
  late MockDashpubApiClient mockApiClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApiClient = MockDashpubApiClient();

    // Mock initializing answer to avoid hanging
    when(() => mockApiClient.isInitialized()).thenAnswer((_) async => false);
  });

  testWidgets('App smoke test', (tester) async {
    // Just verify the app builds without crashing
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Pass the mock client here
    await tester.pumpWidget(DashpubApp(clientOverride: mockApiClient));
    await tester.pumpAndSettle();

    expect(find.byType(DashpubApp), findsOneWidget);
  });
}
