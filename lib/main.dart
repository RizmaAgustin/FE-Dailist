import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login/sign_in.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = NotificationService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await initializeDateFormatting('id_ID', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
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
          home: const SplashDailistPage(),
        );
      },
    );
  }
}

/// Splash / Welcome page sesuai gambar, tanpa Teks DAILIST dan tagline
class SplashDailistPage extends StatelessWidget {
  const SplashDailistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive width/height
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 330;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 12 : 24,
              vertical: isSmall ? 16 : 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Judul Selamat Datang
                Text(
                  "Selamat Datang\nDi Aplikasi Dailist",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Signika',
                    fontSize: isSmall ? 22 : 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: isSmall ? 18 : 28),
                // Logo Dailist (ganti dengan AssetImage jika ada)
                Container(
                  width: isSmall ? 160 : 210,
                  height: isSmall ? 160 : 210,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7FE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/dailist.png',
                      width: isSmall ? 112 : 140,
                      height: isSmall ? 112 : 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: isSmall ? 18 : 28),
                // Deskripsi multi-line manual
                Text(
                  'Yuk, atur tugas-tugasmu biar\nkeseharianmu makin terorganisir dan\nproduktif.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isSmall ? 18 : 28),
                // Tombol
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmall ? 11 : 15,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Di List Yuk!',
                      style: TextStyle(
                        fontFamily: 'Signika',
                        fontWeight: FontWeight.w700,
                        fontSize: isSmall ? 15 : 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmall ? 10 : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
