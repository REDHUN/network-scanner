import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/core/theme/app_theme.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/service/network_service/network_service.dart';
import 'package:ip_tools/service/permission_service/permission_service.dart';
import 'package:ip_tools/view/homescreen/homescreen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'compact dashboard keeps quick actions readable without fake IPs',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final permissions = PermissionService();
      final network = NetworkViewModel(
        NetworkService(),
        permissions,
        ConnectivityService(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkViewModel>.value(
          value: network,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Homescreen(),
          ),
        ),
      );

      expect(find.text('Router: Not available'), findsOneWidget);
      expect(find.text('Router: 10.0.2.2'), findsNothing);
      expect(find.text('Ping & Jitter'), findsOneWidget);
      expect(find.text('Traceroute'), findsOneWidget);
      expect(find.text('Wake-on-LAN'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      network.dispose();
      permissions.dispose();
    },
  );
}
