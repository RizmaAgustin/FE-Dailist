import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_task.dart';
import '../theme/theme_provider.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';

// Helper: Capitalize extension
extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final GlobalKey<_AllTasksContentState> _contentKey = GlobalKey();

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
        title: const Text(
          'Semua Tugas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_round_outlined,
              color: iconColor,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: _AllTasksContent(key: _contentKey),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (result == true) {
            _contentKey.currentState?.refreshTasks();
          }
        },
        backgroundColor: const Color(0xFF2196F3),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class Task {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? priority;
  final DateTime? dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.priority,
    this.dueDate,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      description: json['description'],
      category: (json['category'] as String?)?.toLowerCase(),
      priority: (json['priority'] as String?)?.toLowerCase(),
      dueDate:
          json['deadline'] != null && json['deadline'] != ""
              ? DateTime.parse(json['deadline'])
              : null,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }
}

class _AllTasksContent extends StatefulWidget {
  const _AllTasksContent({super.key});

  @override
  State<_AllTasksContent> createState() => _AllTasksContentState();
}

class _AllTasksContentState extends State<_AllTasksContent> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> refreshTasks() async {
    await _loadTasks(showSnackbar: true);
  }

  Future<void> _loadTasks({bool showSnackbar = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _getToken();
      final result = await ApiService.fetchTasks(token: token ?? '');
      if (result['status'] == 200) {
        final List<dynamic> data = result['body'];
        setState(() {
          _tasks = data.map((json) => Task.fromJson(json)).toList();
          _isLoading = false;
        });
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daftar tugas diperbarui')),
          );
        }
      } else {
        throw Exception('Failed to load tasks: ${result['status']}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat tugas: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final wasCompleted = task.isCompleted;
    setState(() {
      _tasks =
          _tasks.map((t) {
            if (t.id == task.id) {
              return Task(
                id: t.id,
                title: t.title,
                description: t.description,
                category: t.category,
                priority: t.priority,
                dueDate: t.dueDate,
                isCompleted: !t.isCompleted,
              );
            }
            return t;
          }).toList();
    });

    try {
      final token = await _getToken();
      final result = await ApiService.toggleTaskCompletion(
        token: token ?? '',
        taskId: task.id,
        isCompleted:
            !task
                .isCompleted, // <--- INI WAJIB, agar backend update is_completed
      );
      if (result['status'] != 200) {
        print('Response error: ${result['body']}');
        throw Exception('Failed to toggle completion: ${result['body']}');
      }
      await NotificationService.showInstantNotification(
        id: task.id,
        title: wasCompleted ? 'Tugas Ditandai Belum Selesai' : 'Tugas Selesai',
        body: 'Tugas: ${task.title}',
      );
    } catch (e) {
      setState(() {
        _tasks =
            _tasks.map((t) {
              if (t.id == task.id) {
                return Task(
                  id: t.id,
                  title: t.title,
                  description: t.description,
                  category: t.category,
                  priority: t.priority,
                  dueDate: t.dueDate,
                  isCompleted: wasCompleted,
                );
              }
              return t;
            }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change status: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTask(int taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();
      final result = await ApiService.deleteTask(
        token: token ?? '',
        taskId: taskId,
      );
      if (result['status'] == 200) {
        await NotificationService.cancelNotification(taskId);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tugas berhasil dihapus')));
        await _loadTasks();
      } else {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus tugas: $e')));
    }
  }

  Future<void> _navigateToEditTask(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(taskToEdit: task)),
    );
    if (result == true) {
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();

    final completedTasks = _tasks.where((t) => t.isCompleted).toList();
    final lateTasks =
        _tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isBefore(now),
            )
            .toList();
    final priorityTasks =
        _tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  (t.dueDate == null || t.dueDate!.isAfter(now)) &&
                  t.priority == 'tinggi',
            )
            .toList();
    final otherTasks =
        _tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  (t.dueDate == null || t.dueDate!.isAfter(now)) &&
                  t.priority != 'tinggi',
            )
            .toList();

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        children: [
          if (priorityTasks.isNotEmpty) ...[
            _buildSectionTitle('Prioritas Tinggi', Colors.red),
            ...priorityTasks.map(
              (task) => _TaskItem(
                task: task,
                onToggle: () => _toggleTaskCompletion(task),
                onEdit: () => _navigateToEditTask(task),
                onDelete: () => _deleteTask(task.id),
              ),
            ),
          ],
          if (lateTasks.isNotEmpty) ...[
            _buildSectionTitle('Terlambat', Colors.orange),
            ...lateTasks.map(
              (task) => _TaskItem(
                task: task,
                onToggle: () => _toggleTaskCompletion(task),
                onEdit: () => _navigateToEditTask(task),
                onDelete: () => _deleteTask(task.id),
              ),
            ),
          ],
          if (otherTasks.isNotEmpty) ...[
            _buildSectionTitle('Tugas Lainnya', Colors.blue),
            ...otherTasks.map(
              (task) => _TaskItem(
                task: task,
                onToggle: () => _toggleTaskCompletion(task),
                onEdit: () => _navigateToEditTask(task),
                onDelete: () => _deleteTask(task.id),
              ),
            ),
          ],
          if (completedTasks.isNotEmpty) ...[
            _buildSectionTitle('Selesai', Colors.green),
            ...completedTasks.map(
              (task) => _TaskItem(
                task: task,
                onToggle: () => _toggleTaskCompletion(task),
                onEdit: () => _navigateToEditTask(task),
                onDelete: () => _deleteTask(task.id),
              ),
            ),
          ],
          if (priorityTasks.isEmpty &&
              lateTasks.isEmpty &&
              otherTasks.isEmpty &&
              completedTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada tugas',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: color,
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskItem({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dueDateText =
        task.dueDate != null
            ? dateFormat.format(task.dueDate!)
            : 'Tanpa deadline';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deadline: $dueDateText'),
            if (task.category != null)
              Text('Kategori: ${task.category!.capitalize()}'),
            if (task.priority != null)
              Text('Prioritas: ${task.priority!.capitalize()}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}
