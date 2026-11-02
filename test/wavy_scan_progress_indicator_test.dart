import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/common/widgets/wavy_scan_progress_indicator.dart';
import 'package:ip_tools/core/theme/app_theme.dart';

void main() {
  testWidgets('scan wave keeps the original blue and reports actual progress', (
    tester,
  ) async {
    Widget app(double value) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            child: WavyScanProgressIndicator(value: value),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(0.45));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary,
      const Color(0xFF0075FF),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Scan progress')).value,
      '45%',
    );
    expect(tester.getSize(find.byType(WavyScanProgressIndicator)).height, 18);

    await tester.pumpWidget(app(0.8));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Scan progress')).value,
      '80%',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wave respects reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: WavyScanProgressIndicator(value: 0.3)),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Scan progress')).value,
      '30%',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
