import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login/sign_in.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize(); // <--- Inisialisasi notifikasi

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
          themeMode:
              themeProvider.currentTheme, // Gunakan langsung currentTheme
          navigatorKey: navigatorKey, // ini penting!
          home: OnboardingScreen(),
        );
      },
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.1),
          Text(
            'Selamat Datang',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 34,
              fontFamily: 'Signika',
              fontWeight: FontWeight.w700,
              height: 1.26,
              letterSpacing: -0.68,
            ),
          ),
          Text(
            'Di Aplikasi Dailist',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 34,
              fontFamily: 'Signika',
              fontWeight: FontWeight.w700,
              height: 1.26,
              letterSpacing: -0.68,
            ),
          ),
          SizedBox(height: size.height * 0.05),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size.width * 0.45,
                height: size.width * 0.45,
                decoration: BoxDecoration(
                  color: Color(0xFFEDF7FE),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                width: size.width * 0.35,
                height: size.width * 0.35,
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.04),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
            child: Text(
              'Yuk, atur tugas-tugasmu biar\nkeseharianmu makin terorganisir dan\nproduktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF939393),
                fontSize: 18,
                fontFamily: 'Signika',
                fontWeight: FontWeight.w400,
                height: 1.24,
                letterSpacing: -0.36,
              ),
            ),
          ),
          Expanded(child: SizedBox()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: SizedBox(
              width: double.infinity,
              height: size.height * 0.07,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Di List Yuk!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Signika',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.03),
        ],
      ),
    );
  }
}
