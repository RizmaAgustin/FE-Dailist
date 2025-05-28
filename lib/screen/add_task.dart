import 'package:dailist/screen/calender.dart';
import 'package:flutter/material.dart';
import 'all_task.dart';
import 'setting.dart';
import 'home.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _judulController = TextEditingController();
  String? _kategori;
  final TextEditingController _prioritasController = TextEditingController();
  DateTime? _tanggal;
  TimeOfDay? _waktu;
  bool _aturPengingat = false;
  final TextEditingController _catatanController = TextEditingController();
  int _selectedIndex = 0;

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _tanggal = picked;
      });
    }
  }

  Future<void> _pilihWaktu(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _waktu ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _waktu = picked;
      });
    }
  }

  void _onItemTapped(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const AllTasksScreen();
        break;
      case 2:
        page = const CalendarScreen();
        break;
      case 3:
        page = const SettingsScreen();
        break;
      default:
        page = const HomePage();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFEDF7FE);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final inputColor =
        isDarkMode ? Colors.grey[800] ?? Colors.grey : Colors.white;
    final borderColor = isDarkMode ? Colors.grey : Colors.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
              icon: Icons.radio_button_unchecked,
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Color inputColor,
    Color borderColor, {
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
        filled: true,
        fillColor: inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(color: borderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 15.0,
        ),
      ),
    );
  }

  Widget _buildDropdown(Color inputColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
        fillColor: inputColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 15.0,
        ),
      ),
      value: _kategori,
      hint: const Text('Pilih Kategori'),
      items:
          ['Kerja', 'Pribadi', 'Belajar', 'Lain-lain'].map((value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _kategori = newValue;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, color: Colors.grey),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _pilihTanggal(context),
          child: Text(
            _tanggal == null
                ? 'Atur Tanggal'
                : '${_tanggal!.day}-${_tanggal!.month}-${_tanggal!.year}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.grey),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _pilihWaktu(context),
          child: Text(
            _waktu == null ? 'Atur Waktu' : _waktu!.format(context),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildReminder() {
    return Row(
      children: [
        const Icon(Icons.notifications_active_outlined, color: Colors.grey),
        const SizedBox(width: 12),
        const Text(
          'Atur Pengingat',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const Spacer(),
        Switch(
          value: _aturPengingat,
          onChanged: (value) {
            setState(() {
              _aturPengingat = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AllTasksScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          ),
          child: const Text(
            'Simpan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
