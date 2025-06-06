import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = 'Nama Pengguna';
  String userEmail = 'Email Pengguna';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email') ?? 'Email tidak tersedia';
      userName = prefs.getString('name') ?? 'Nama tidak tersedia';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final backgroundColor =
        isDark ? const Color(0xFF303030) : const Color(0xFFEDF7FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: iconColor,
            fontSize: 24,
            fontFamily: 'Signika',
            fontWeight: FontWeight.w600,
            letterSpacing: -0.48,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: iconColor,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildNameCard(isDark, userName),
                  const SizedBox(height: 8.0),
                  _buildEmailCard(isDark, userEmail),
                  const SizedBox(height: 16.0),
                  _buildNotificationCard(isDark),
                  const SizedBox(height: 16.0),
                  _buildLogoutButton(context),
                ],
              ),
    );
  }

  Widget _buildNameCard(bool isDark, String name) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 30.0, color: textColor),
          const SizedBox(width: 16.0),
          Text(
            name,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard(bool isDark, String email) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 46.0),
        child: Text(email, style: TextStyle(fontSize: 18.0, color: textColor)),
      ),
    );
  }

  Widget _buildNotificationCard(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        'Notifikasi',
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).currentTheme == ThemeMode.dark;
    final buttonColor = isDark ? Colors.red[800] : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: Icon(Icons.logout, color: buttonColor),
        title: Text(
          'Keluar',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w400,
            color: buttonColor,
          ),
        ),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('email');
          await prefs.remove('name');

          // Navigasi ke halaman login
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        },
      ),
    );
  }
}
