import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/service/network_scanner_service/network_scanner_service.dart';
import 'package:ip_tools/view/splash_screen/splash_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'service/network_connectivity_service/network_connectivity_service.dart';
import 'service/network_service/network_service.dart';
import 'service/permission_service/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NetworkService>(create: (_) => NetworkService()),
        Provider<PermissionService>(create: (_) => PermissionService()),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        Provider(create: (_) => NetworkScannerService()),
        ChangeNotifierProvider<NetworkViewModel>(
          create: (context) => NetworkViewModel(
            context.read<NetworkService>(),
            context.read<PermissionService>(),
            context.read<ConnectivityService>(),
          ),
        ),
        ChangeNotifierProvider(create: (c) => NetworkScannerProvider()),
      ],
      child: MaterialApp(
        title: 'IP Tools : Network Scanner',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
