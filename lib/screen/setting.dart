import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final backgroundColor =
        isDark ? const Color(0xFF303030) : const Color(0xFFEDF7FE);
    final cardColor = isDark ? Colors.grey[800]! : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = snapshot.data!;

          if (prefs.getString('name') == null ||
              prefs.getString('name')!.isEmpty) {
            return _buildEditNameFirst(context, isDark);
          }

          final userName = prefs.getString('name')!;
          final userEmail = prefs.getString('email') ?? 'You@gmail.com';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileSection(
                  context,
                  isDark,
                  userName,
                  userEmail,
                  cardColor,
                  textColor,
                ),
                const SizedBox(height: 24),
                _buildNotificationSection(
                  isDark,
                  cardColor,
                  textColor,
                  context,
                ),
                const SizedBox(height: 24),
                _buildLogoutSection(context, isDark),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    bool isDark,
    String userName,
    String userEmail,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.blueGrey[700]! : Colors.blue[50]!,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: isDark ? Colors.blue[200]! : Colors.blue[600]!,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditNameDialog(context, userName),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(
    bool isDark,
    Color cardColor,
    Color textColor,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none, size: 24, color: textColor),
          const SizedBox(width: 16),
          Text('Notifikasi', style: TextStyle(fontSize: 16, color: textColor)),
          const Spacer(),
          FutureBuilder<bool>(
            future: NotificationService.areNotificationsEnabled(),
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? true;
              return Switch(
                value: enabled,
                onChanged: (value) async {
                  if (value) {
                    await NotificationService.requestPermission();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notifikasi diaktifkan'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    await NotificationService.cancelAllNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Semua notifikasi dinonaktifkan'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                activeColor: Colors.blue,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          _buildLogoutButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildEditNameFirst(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final cardColor = isDark ? Colors.grey[800]! : Colors.white;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 48,
              color: textColor.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Lengkapi Profil Anda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Silakan masukkan nama Anda untuk memulai',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          () => _showEditNameDialog(
                            context,
                            '',
                            isFirstTime: true,
                          ),
                      child: const Text('Masukkan Nama'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final bgColor = isDark ? Colors.grey[800]! : Colors.white;

    final prefs = await SharedPreferences.getInstance();
    final textController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFirstTime ? 'Masukkan Nama Anda' : 'Ubah Nama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Nama',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (textController.text.trim().isNotEmpty) {
                            await prefs.setString(
                              'name',
                              textController.text.trim(),
                            );
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
                              SnackBar(
                                content: const Text('Nama berhasil disimpan'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.red[800]! : Colors.red[600]!,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () => _showLogoutConfirmation(context),
        icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.9)),
        label: const Text(
          'Keluar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF424242) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.orange[400],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Konfirmasi Keluar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Anda akan keluar dari akun Anda. Yakin ingin melanjutkan?',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: textColor, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _performLogout(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600]!,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ya, Keluar',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      if (token != null) {
        await ApiService.logoutUser(token);
      }
      // Cancel semua notifikasi saat logout
      await NotificationService.cancelAllNotifications();
      await _clearLocalDataAndNavigate(context);
    } catch (e) {
      await NotificationService.cancelAllNotifications();
      await _clearLocalDataAndNavigate(context);
    }
  }

  Future<void> _clearLocalDataAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda telah logout'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
