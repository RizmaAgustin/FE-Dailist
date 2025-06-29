import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_in.dart';
import '../services/api_services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );
      final responseData = result['body'];
      if (result['status'] == 200 || result['status'] == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameController.text.trim());
        await prefs.setString('email', _emailController.text.trim());

        _showSuccessDialog(context);
      } else {
        String errorMessage = 'Registrasi gagal';
        if (responseData is Map && responseData.containsKey('errors')) {
          errorMessage = _parseErrorMessages(responseData['errors']);
        } else if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseErrorMessages(Map<String, dynamic> errors) {
    return errors.entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join('\n');
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Registrasi Berhasil'),
            content: const Text(
              'Akun Anda telah berhasil dibuat. Silakan login.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Size screen = MediaQuery.of(context).size;

    Color getTextFieldColor() => isDarkMode ? Colors.grey[800]! : Colors.white;
    Color getTextColor() => isDarkMode ? Colors.white : const Color(0xFF333333);
    Color getBackgroundColor() =>
        isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFEDF7FE);

    double baseWidth = 400;
    double scale = (screen.width < baseWidth ? screen.width / baseWidth : 1.0);

    return Scaffold(
      backgroundColor: getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: getBackgroundColor(),
        title: const Text(
          'Buat Akun',
          style: TextStyle(fontFamily: 'Signika', fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screen.height,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screen.width > 500 ? 48.0 : 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tambahkan sedikit spasi atas untuk responsif (tidak terlalu ke atas/tidak terlalu bawah)
                    SizedBox(height: screen.height * 0.07),
                    // "Daftar" title kiri atas
                    Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontFamily: 'Signika',
                        fontWeight: FontWeight.w700,
                        color: getTextColor(),
                      ),
                    ),
                    SizedBox(height: 18 * scale),
                    _buildLabel('Nama Lengkap :', getTextColor()),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Masukkan nama lengkap',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                      color: getTextFieldColor(),
                      textColor: getTextColor(),
                    ),
                    SizedBox(height: 12 * scale),
                    _buildLabel('Email :', getTextColor()),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'contoh@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!_isValidEmail(value)) {
                          return 'Masukkan email yang valid';
                        }
                        return null;
                      },
                      color: getTextFieldColor(),
                      textColor: getTextColor(),
                    ),
                    SizedBox(height: 12 * scale),
                    _buildLabel('Password :', getTextColor()),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: '********',
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                      color: getTextFieldColor(),
                      textColor: getTextColor(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: getTextColor(),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    _buildLabel('Konfirmasi Password :', getTextColor()),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: '********',
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap konfirmasi password';
                        }
                        if (value != _passwordController.text) {
                          return 'Password tidak sama';
                        }
                        return null;
                      },
                      color: getTextFieldColor(),
                      textColor: getTextColor(),
                    ),
                    SizedBox(height: 20 * scale),
                    // Tombol Daftar dan Sudah punya akun? Masuk di kanan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 46 * scale,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Signika',
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontFamily: 'Roboto',
                                    color: getTextColor(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignInPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20 * scale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Roboto',
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color color,
    required Color textColor,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6 * 255)),
        filled: true,
        fillColor: color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        errorStyle: const TextStyle(fontSize: 12),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
