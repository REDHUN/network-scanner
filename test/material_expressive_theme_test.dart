import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'expressive theme supports navigation, filtering and touch targets',
    (tester) async {
      var selected = 0;
      var filtered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Center(
                child: FilterChip(
                  label: const Text('Online'),
                  selected: filtered,
                  onSelected: (value) => setState(() => filtered = value),
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (value) =>
                    setState(() => selected = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.devices_outlined),
                    label: 'Devices',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        Theme.of(tester.element(find.byType(Scaffold))).useMaterial3,
        isTrue,
      );
      const blue = Color(0xFF0075FF);
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.colorScheme.primary, blue);
      expect(theme.colorScheme.secondary, blue);
      expect(theme.colorScheme.surfaceTint, blue);
      expect(theme.colorScheme.secondaryContainer, const Color(0xFFE4F1FF));
      expect(
        theme.navigationBarTheme.iconTheme?.resolve({
          WidgetState.selected,
        })?.color,
        blue,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(
        tester.getSize(find.byType(NavigationBar)).height,
        greaterThanOrEqualTo(72),
      );

      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );

      await tester.tap(find.text('Online'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).selected,
        isTrue,
      );
    },
  );
}
