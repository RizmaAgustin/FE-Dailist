import 'package:dailist/screen/calender.dart';
import 'package:flutter/material.dart';
import 'all_task.dart';
import 'setting.dart';
import 'home.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _judulController = TextEditingController();
  final _prioritasController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _kategori;
  DateTime? _tanggal;
  TimeOfDay? _waktu;
  bool _aturPengingat = false;
  int _selectedIndex = 0;

  final int userId = 1; // contoh userId, sesuaikan

  void _onItemTapped(int index) {
    final pages = [
      const HomePage(),
      const AllTasksScreen(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => pages[index]),
    );
  }

  Future<String?> getToken() async {
    // Gantilah dengan token valid milikmu (bisa simpan di secure storage)
    return '69|gKFfIeRmoOWL9YnAGWCQFUc6sSCr0vqUA3p2a9xU9280832d';
  }

  Future<bool> addTask() async {
    if (_tanggal == null || _waktu == null) return false;

    final deadline = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _waktu!.hour,
      _waktu!.minute,
    );

    final url = Uri.parse(
      'http://127.0.0.1:8000/api/tasks',
    ); // URL API Laravel-mu
    final token = await getToken();

    final body = {
      'user_id': userId.toString(),
      'title': _judulController.text,
      'description': _catatanController.text,
      'category': _kategori ?? '',
      'priority': _prioritasController.text,
      'deadline': DateFormat('yyyy-MM-dd HH:mm:ss').format(deadline),
      'reminder': _aturPengingat ? '1' : '0',
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return false;
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        _kategori == null ||
        _tanggal == null ||
        _waktu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap isi semua field dan pilih kategori, tanggal, dan waktu.',
          ),
        ),
      );
      return;
    }

    final success = await addTask();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil ditambahkan!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AllTasksScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menambahkan tugas.')));
    }
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _pilihWaktu(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _waktu ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _waktu = picked);
  }

  // ... kode widget build, _buildLabel, _buildTextField, _buildDropdown, _buildDatePicker,
  // _buildTimePicker, _buildReminder tetap sama seperti sebelumnya ...

  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: const Text(
            'Simpan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFEDF7FE);
    final textColor = isDark ? Colors.white : Colors.black;
    final inputColor = isDark ? Colors.grey[800]! : Colors.white;
    final borderColor = isDark ? Colors.grey : Colors.blue;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Judul :', textColor),
              const SizedBox(height: 8),
              _buildTextField(
                _judulController,
                'Judul Tugas',
                inputColor,
                borderColor,
              ),

              const SizedBox(height: 16),
              _buildLabel('Kategori :', textColor),
              const SizedBox(height: 8),
              _buildDropdown(inputColor, borderColor),

              const SizedBox(height: 16),
              _buildLabel('Prioritas :', textColor),
              const SizedBox(height: 8),
              _buildTextField(
                _prioritasController,
                'Prioritas Tugas',
                inputColor,
                borderColor,
                icon: Icons.flag_outlined,
              ),

              const SizedBox(height: 16),
              _buildLabel('Tanggal :', textColor),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 8),
              _buildTimePicker(),

              const SizedBox(height: 16),
              _buildLabel('Pengingat :', textColor),
              const SizedBox(height: 8),
              _buildReminder(),

              const SizedBox(height: 16),
              _buildLabel('Catatan :', textColor),
              const SizedBox(height: 8),
              _buildTextField(
                _catatanController,
                'Deskripsi',
                inputColor,
                borderColor,
                maxLines: 5,
              ),

              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.task_outlined), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    Color fillColor,
    Color borderColor, {
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator:
          (value) =>
              value == null || value.isEmpty ? 'Tidak boleh kosong' : null,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        hintText: hintText,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildDropdown(Color fillColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _kategori,
          isExpanded: true,
          hint: const Text('Pilih kategori'),
          items: const [
            DropdownMenuItem(value: 'Kuliah', child: Text('Kuliah')),
            DropdownMenuItem(value: 'Kerja', child: Text('Kerja')),
            DropdownMenuItem(value: 'Pribadi', child: Text('Pribadi')),
          ],
          onChanged: (val) => setState(() => _kategori = val),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return OutlinedButton(
      onPressed: () => _pilihTanggal(context),
      child: Text(
        _tanggal == null
            ? 'Pilih tanggal'
            : DateFormat('dd-MM-yyyy').format(_tanggal!),
      ),
    );
  }

  Widget _buildTimePicker() {
    return OutlinedButton(
      onPressed: () => _pilihWaktu(context),
      child: Text(_waktu == null ? 'Pilih waktu' : _waktu!.format(context)),
    );
  }

  Widget _buildReminder() {
    return Row(
      children: [
        Switch(
          value: _aturPengingat,
          onChanged: (val) => setState(() => _aturPengingat = val),
        ),
        const SizedBox(width: 8),
        const Text('Atur Pengingat'),
      ],
    );
  }
}
