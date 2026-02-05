import 'dart:async';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_ui/main.dart';
import 'package:dashpub_ui/src/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class MockDashpubApiClient extends Mock implements DashpubApiClient {}

void main() {
  group('HomePage', () {
    late MockDashpubApiClient mockApiClient;
    setUp(() {
      mockApiClient = MockDashpubApiClient();
      apiClient = mockApiClient;
    });

    tearDown(() {
      // Restore if possible
    });

    Widget createWidgetUnderTest() {
      return ShadcnApp(home: const HomePage());
    }

    testWidgets('renders loading indicator initially', (tester) async {
      // Set large surface size
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final completer = Completer<ListApi>();

      when(
        () => mockApiClient.getPackages(q: any(named: 'q')),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());
      // Pump a frame to ensure build starts
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to finish test cleanly
      completer.complete(ListApi(0, []));
      await tester.pumpAndSettle();
    });

    testWidgets('renders package list when loaded', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final packages = [
        ListApiPackage('pkg1', 'Description', [], '1.0.0', DateTime.now()),
      ];
      when(
        () => mockApiClient.getPackages(q: any(named: 'q')),
      ).thenAnswer((_) async => ListApi(1, packages));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('pkg1'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
    });

    testWidgets('renders error message on failure', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Return a Future that completes with an error
      when(() => mockApiClient.getPackages(q: any(named: 'q'))).thenAnswer(
        (_) => Future.error('Network Error'),
      ); // Just string error to match simpler message

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // The HomePage renders 'Error: ${snapshot.error}'
      // If we throw 'Network Error', text should be 'Error: Network Error'
      expect(find.textContaining('Error: Network Error'), findsOneWidget);
    });
  });
}
