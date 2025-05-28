import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart'; // Pastikan path provider benar

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final backgroundColor =
        isDark
            ? const Color(0xFF303030)
            : const Color(0xFFEDF7FE); // Warna biru muda dari HomePage

    return Scaffold(
      backgroundColor: backgroundColor, // Background full biru sesuai tema
      appBar: AppBar(
        backgroundColor:
            backgroundColor, // Background AppBar jadi biru sesuai tema
        elevation: 0, // Hilangkan shadow AppBar
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: iconColor, // Warna teks AppBar mengikuti warna ikon
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNameCard(isDark),
          const SizedBox(height: 8.0),
          _buildEmailCard(isDark),
          const SizedBox(height: 16.0),
          _buildNotificationCard(isDark),
        ],
      ),
    );
  }

  Widget _buildNameCard(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor =
        isDark ? Colors.grey[800] : Colors.white; // Tambahkan warna card
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor, // Gunakan warna card yang sesuai tema
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 30.0, color: textColor),
          const SizedBox(width: 16.0),
          Text(
            'Nama Kamu',
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

  Widget _buildEmailCard(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor =
        isDark ? Colors.grey[800] : Colors.white; // Tambahkan warna card
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor, // Gunakan warna card yang sesuai tema
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 46.0),
        child: Text(
          'You@gmail.com',
          style: TextStyle(fontSize: 18.0, color: textColor),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor =
        isDark ? Colors.grey[800] : Colors.white; // Tambahkan warna card
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor, // Gunakan warna card yang sesuai tema
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
}
