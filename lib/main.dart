import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netra/service/network_scanner_service/network_scanner_service.dart';
import 'package:netra/view/homescreen/homescreen.dart';
import 'package:netra/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:netra/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'service/network_connectivity_service/network_connectivity_service.dart';
import 'service/network_service/network_service.dart';
import 'service/permission_service/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await configureNetworkTools(
  dir.path,
  enableDebugging: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NetworkService>(
          create: (_) => NetworkService(),
        ),
        Provider<PermissionService>(
          create: (_) => PermissionService(),
        ),
        Provider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
        Provider(create: (_) => NetworkScannerService()),
        ChangeNotifierProvider<NetworkViewModel>(
          create: (context) => NetworkViewModel(
            context.read<NetworkService>(),
            context.read<PermissionService>(),
             context.read<ConnectivityService>(),

          ),

        ),
        ChangeNotifierProvider(
          create: (c) => NetworkScannerProvider(

          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Homescreen(),
      ),
    );
  }
}


