import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_web/screens/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen renders KPIs and AI Button', (WidgetTester tester) async {
    // Set surface size to prevent AppBar overflow in test environment
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    // Note: We wrap in MaterialApp to provide context
    await tester.pumpWidget(const MaterialApp(
      home: DashboardScreen(),
    ));

    // Verify Dashboard title or icon exists
    expect(find.text('SmartChain AI'), findsOneWidget);

    // Verify KPI cards exist by their titles
    expect(find.text('Total Shipments'), findsOneWidget);
    expect(find.text('On-Time %'), findsOneWidget);
    expect(find.text('Active Alerts'), findsOneWidget);
    expect(find.text('Avg Delay'), findsOneWidget);

    // Verify "Run AI Analysis" button exists
    expect(find.text('Run AI Analysis'), findsOneWidget);
    expect(find.byIcon(Icons.analytics), findsOneWidget);
  });

  testWidgets('KPI cards show correct initial mock values', (WidgetTester tester) async {
    // Set surface size to prevent AppBar overflow
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(
      home: DashboardScreen(),
    ));

    // Based on getMockShipments returns 8 shipments
    expect(find.text('8'), findsOneWidget); // Total Shipments
    
    // On-time percentage calculation:
    // 8 total. 3 are not 'on_time' (delayed, critical, delayed).
    // (8 - 3) / 8 = 5/8 = 62.5%
    expect(find.text('62.5%'), findsOneWidget);
  });
}
