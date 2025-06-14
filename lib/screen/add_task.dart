import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_task.dart';
import 'calender.dart';
import 'setting.dart';
import '../services/notification_service.dart';
import '../services/api_services.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;
  final Function()? onTaskUpdated;

  const AddTaskScreen({super.key, this.taskToEdit, this.onTaskUpdated});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _catatanController = TextEditingController();

  static const List<String> _kategoriOptions = ['Kerja', 'Pribadi', 'Belajar'];
  static const List<String> _prioritasOptions = ['Tinggi', 'Sedang', 'Rendah'];

  String? _kategori;
  String? _prioritas;
  DateTime? _tanggal;
  TimeOfDay? _waktu;
  bool _aturPengingat = false;
  bool _isCompleted = false;
  int _selectedIndex = 0;
  Timer? _deadlineTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final task = widget.taskToEdit!;
    _judulController.text = task.title;
    _catatanController.text = task.description ?? '';
    _kategori =
        _kategoriOptions.contains(task.category)
            ? task.category
            : _kategoriOptions.first;
    _prioritas =
        _prioritasOptions.contains(task.priority)
            ? task.priority
            : _prioritasOptions.first;
    _isCompleted = task.isCompleted;
    _aturPengingat = task.dueDate != null;

    if (task.dueDate != null) {
      _tanggal = task.dueDate;
      _waktu = TimeOfDay.fromDateTime(task.dueDate!);
      _startDeadlineTimer(task.dueDate!);
    }
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    _judulController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _startDeadlineTimer(DateTime deadline) {
    _deadlineTimer?.cancel();
    final now = DateTime.now();
    final durationUntilDeadline = deadline.difference(now);
    if (durationUntilDeadline.isNegative) return;
    final alertTime = deadline.subtract(const Duration(minutes: 1));
    final alertDuration = alertTime.difference(now);
    _deadlineTimer = Timer(alertDuration, () {
      _showDeadlineAlert();
    });
  }

  void _showDeadlineAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deadline Mendekati!'),
          content: Text(
            'Tugas "${_judulController.text}" akan segera berakhir pada '
            '${DateFormat('dd MMMM yyyy HH:mm').format(DateTime(_tanggal!.year, _tanggal!.month, _tanggal!.day, _waktu!.hour, _waktu!.minute))}',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> saveTask() async {
    if (_tanggal == null || _waktu == null) return false;

    final deadline = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _waktu!.hour,
      _waktu!.minute,
    );

    _startDeadlineTimer(deadline);

    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan, silakan login ulang.'),
        ),
      );
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.saveTask(
        token: token,
        taskId: widget.taskToEdit?.id,
        title: _judulController.text,
        description: _catatanController.text,
        category: _kategori ?? '',
        priority: _prioritas ?? '',
        deadline: deadline,
        reminder: _aturPengingat,
        isCompleted: _isCompleted,
      );

      // Notifikasi: hanya jika pengingat diaktifkan
      if ((result['status'] == 200 || result['status'] == 201) &&
          _aturPengingat) {
        final deadlineNotif = DateTime(
          _tanggal!.year,
          _tanggal!.month,
          _tanggal!.day,
          _waktu!.hour,
          _waktu!.minute,
        );

        // Gunakan id unik (bisa dari API jika ada, atau timestamp)
        final notifId =
            widget.taskToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000;

        await NotificationService.scheduleNotification(
          id: notifId,
          title: 'Pengingat Tugas',
          body: _judulController.text,
          scheduledDateTime: deadlineNotif,
        );
      }

      setState(() {
        _isLoading = false;
      });

      return result['status'] == 200 || result['status'] == 201;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan tugas: $e')));
      return false;
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        _kategori == null ||
        _prioritas == null ||
        _tanggal == null ||
        _waktu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap isi semua field dan pilih kategori, prioritas, tanggal, dan waktu.',
          ),
        ),
      );
      return;
    }

    final success = await saveTask();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.taskToEdit == null
                ? 'Tugas berhasil ditambahkan!'
                : 'Tugas berhasil diperbarui!',
          ),
        ),
      );
      if (widget.onTaskUpdated != null) {
        widget.onTaskUpdated!();
      }
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan tugas.')));
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

  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                  : const Text(
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

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Color fillColor,
    Color borderColor,
  ) {
    return TextFormField(
      controller: controller,
      validator:
          (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildDropdownKategori(Color fillColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      value: _kategori,
      items:
          _kategoriOptions.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _kategori = newValue;
        });
      },
      validator: (value) => value == null ? 'Wajib dipilih' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildDropdownPrioritas(Color fillColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      value: _prioritas,
      items:
          _prioritasOptions.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _prioritas = newValue;
        });
      },
      validator: (value) => value == null ? 'Wajib dipilih' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _pilihTanggal(context),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
        ),
        child: Text(
          _tanggal == null
              ? 'Pilih tanggal'
              : DateFormat('dd MMMM yyyy').format(_tanggal!),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () => _pilihWaktu(context),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
        ),
        child: Text(_waktu == null ? 'Pilih waktu' : _waktu!.format(context)),
      ),
    );
  }

  Widget _buildReminder() {
    return SwitchListTile(
      title: const Text('Aktifkan Pengingat'),
      value: _aturPengingat,
      onChanged: (val) => setState(() => _aturPengingat = val),
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
        title: Text(
          widget.taskToEdit == null ? 'Tambah Tugas' : 'Edit Tugas',
          style: TextStyle(color: textColor),
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
              _buildDropdownKategori(inputColor, borderColor),
              const SizedBox(height: 16),
              _buildLabel('Prioritas :', textColor),
              const SizedBox(height: 8),
              _buildDropdownPrioritas(inputColor, borderColor),
              const SizedBox(height: 16),
              _buildLabel('Tanggal :', textColor),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 8),
              _buildTimePicker(),
              const SizedBox(height: 16),
              _buildLabel('Status :', textColor),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text('Selesai', style: TextStyle(color: textColor)),
                value: _isCompleted,
                onChanged: (val) => setState(() => _isCompleted = val),
              ),
              const SizedBox(height: 16),
              _buildLabel('Pengingat :', textColor),
              const SizedBox(height: 8),
              _buildReminder(),
              const SizedBox(height: 16),
              _buildLabel('Catatan :', textColor),
              const SizedBox(height: 8),
              _buildTextField(
                _catatanController,
                'Catatan',
                inputColor,
                borderColor,
              ),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          final pages = [
            const AddTaskScreen(),
            const AllTasksScreen(),
            const CalendarScreen(),
            const SettingsScreen(),
          ];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => pages[index]),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tugas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Kalender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
