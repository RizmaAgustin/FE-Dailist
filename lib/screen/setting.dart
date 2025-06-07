import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          onPressed: () => Navigator.pop(context),
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
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          // Tampilkan loading indicator sampai data siap
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = snapshot.data!;

          // Jika nama belum ada, langsung tampilkan form edit
          if (prefs.getString('name') == null ||
              prefs.getString('name')!.isEmpty) {
            return _buildEditNameFirst(context, isDark);
          }

          // Jika data sudah ada, tampilkan halaman settings normal
          final userName = prefs.getString('name')!;
          final userEmail = prefs.getString('email') ?? 'You@gmail.com';

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildNameCard(isDark, userName, context),
              const SizedBox(height: 8.0),
              _buildEmailCard(isDark, userEmail),
              const SizedBox(height: 16.0),
              _buildNotificationCard(isDark),
              const SizedBox(height: 16.0),
              _buildLogoutButton(context, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditNameFirst(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  Text(
                    'Silakan masukkan nama Anda',
                    style: TextStyle(fontSize: 18.0, color: textColor),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed:
                        () =>
                            _showEditNameDialog(context, '', isFirstTime: true),
                    child: const Text('Masukkan Nama'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameCard(bool isDark, String userName, BuildContext context) {
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
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: textColor),
            onPressed: () => _showEditNameDialog(context, userName),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    String currentName, {
    bool isFirstTime = false,
  }) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    final prefs = await SharedPreferences.getInstance();
    final textController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder:
          (context) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: isDark ? Colors.grey[800] : Colors.white,
            ),
            child: AlertDialog(
              title: Text(
                isFirstTime ? 'Masukkan Nama Anda' : 'Ubah Nama',
                style: TextStyle(color: textColor),
              ),
              content: TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  labelStyle: TextStyle(color: textColor),
                  border: const OutlineInputBorder(),
                ),
                style: TextStyle(color: textColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(color: textColor)),
                ),
                TextButton(
                  onPressed: () async {
                    if (textController.text.trim().isNotEmpty) {
                      await prefs.setString('name', textController.text.trim());
                      Navigator.pop(context);

                      if (isFirstTime) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama berhasil disimpan')),
                      );
                    }
                  },
                  child: Text('Simpan', style: TextStyle(color: textColor)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmailCard(bool isDark, String userEmail) {
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
        child: Text(
          userEmail,
          style: TextStyle(fontSize: 18.0, color: textColor),
        ),
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

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    final buttonColor = isDark ? Colors.red[700] : Colors.red;
    final textColor = isDark ? Colors.white : Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: () => _showLogoutConfirmation(context),
      child: Text(
        'Logout',
        style: TextStyle(
          color: textColor,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return showDialog(
      context: context,
      builder:
          (context) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: isDark ? Colors.grey[800] : Colors.white,
            ),
            child: AlertDialog(
              title: Text(
                'Konfirmasi Logout',
                style: TextStyle(color: textColor),
              ),
              content: Text(
                'Apakah Anda yakin ingin logout?',
                style: TextStyle(color: textColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(color: textColor)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // Tutup dialog
                    await _performLogout(context);
                  },
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      await _clearLocalDataAndNavigate(context);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _clearLocalDataAndNavigate(context);
      } else {
        await _clearLocalDataAndNavigate(context);
      }
    } catch (e) {
      await _clearLocalDataAndNavigate(context);
    }
  }

  Future<void> _clearLocalDataAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Anda telah logout')));
  }
}
