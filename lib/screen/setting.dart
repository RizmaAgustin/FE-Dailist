import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../login/sign_in.dart';

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
          final userEmail = prefs.getString('email') ?? 'you@email.com';

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
                NotificationSection(
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 24),
                _buildLogoutSection(context, isDark),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? Colors.blueGrey : Colors.blue[100],
            child: Icon(
              Icons.person,
              color: isDark ? Colors.white : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditNameDialog(context, userName),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutConfirmation(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => _showEditNameDialog(
                            context,
                            '',
                            isFirstTime: true,
                          ),
                      child: const Text('Masukkan Nama'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isFirstTime ? 'Masukkan Nama Anda' : 'Ubah Nama'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nama'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    await prefs.setString('name', controller.text.trim());
                    Navigator.pop(context);
                    if (isFirstTime) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama berhasil disimpan')),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi Keluar'),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari akun ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performLogout(context);
                },
                child: const Text('Ya, Keluar'),
              ),
            ],
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
      await NotificationService.cancelAllNotifications();
    } catch (_) {}

    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anda telah logout')));
    }
  }
}

// ---- NOTIFICATION SECTION STATEFUL ----

class NotificationSection extends StatefulWidget {
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  const NotificationSection({
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    Key? key,
  }) : super(key: key);

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  late Future<bool> _enabledFuture;

  @override
  void initState() {
    super.initState();
    _enabledFuture = NotificationService.areNotificationsEnabled();
  }

  void _refresh() {
    setState(() {
      _enabledFuture = NotificationService.areNotificationsEnabled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none, size: 24, color: widget.textColor),
          const SizedBox(width: 16),
          Text(
            'Notifikasi',
            style: TextStyle(fontSize: 16, color: widget.textColor),
          ),
          const Spacer(),
          FutureBuilder<bool>(
            future: _enabledFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(strokeWidth: 2);
              }
              final enabled = snapshot.data!;
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
                        content: const Text('Notifikasi dimatikan'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                  _refresh(); // refresh status
                },
                activeColor: Colors.blue,
              );
            },
          ),
        ],
      ),
    );
  }
}
