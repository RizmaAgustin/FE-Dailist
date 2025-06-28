import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login/sign_in.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = NotificationService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi notifikasi (timezone otomatis)
  await NotificationService.initialize();

  // Minta izin exact alarm SEKALI di awal aplikasi (gunakan context navigatorKey)
  // Tunggu hingga navigatorKey punya context (harus setelah runApp)
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );

  // Tunggu beberapa microseconds agar context tersedia
  Future.delayed(const Duration(milliseconds: 200), () async {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null) {
      await NotificationService.requestExactAlarmPermissionWithDialog(context);
    }
  });

  // Inisialisasi locale tanggal Indonesia
  await initializeDateFormatting('id_ID', null);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Dailist',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.currentTheme,
          navigatorKey: navigatorKey,
          home: const SignInPage(),
        );
      },
    );
  }
}
