import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_task.dart';
import '../theme/theme_provider.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({Key? key}) : super(key: key);

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
      category: json['category'],
      priority: json['priority'],
      dueDate:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }
}

class _AllTasksContent extends StatefulWidget {
  const _AllTasksContent({Key? key}) : super(key: key);

  @override
  State<_AllTasksContent> createState() => _AllTasksContentState();
}

class _AllTasksContentState extends State<_AllTasksContent> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> refreshTasks() async {
    await _loadTasks(showSnackbar: true);
  }

  Future<void> _loadTasks({bool showSnackbar = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/tasks?email=rizmaagustin66@gmail.com',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _tasks = data.map((json) => Task.fromJson(json)).toList();
            _isLoading = false;
            _lastRefreshTime = DateTime.now();
          });
        }
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daftar tugas diperbarui')),
          );
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat tugas: $e';
          _isLoading = false;
        });
      }
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
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/tasks/${task.id}/toggle-completion',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _loadTasks();
      } else {
        throw Exception('Failed to toggle completion');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
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
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
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

  Widget _buildTaskList() {
    final now = DateTime.now();
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
                  (t.dueDate == null || !t.dueDate!.isBefore(now)),
            )
            .toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return ListView(
      children: [
        if (lateTasks.isNotEmpty)
          _TaskSection(
            title: 'Terlambat',
            color: Colors.orange,
            tasks: lateTasks,
            onToggle: _toggleTaskCompletion,
            onEdit: _navigateToEditTask,
            onDelete: _deleteTask,
          ),
        if (priorityTasks.isNotEmpty)
          _TaskSection(
            title: 'Tugas Prioritas',
            color: Colors.blue,
            tasks: priorityTasks,
            onToggle: _toggleTaskCompletion,
            onEdit: _navigateToEditTask,
            onDelete: _deleteTask,
          ),
        if (completedTasks.isNotEmpty)
          _TaskSection(
            title: 'Tugas Selesai',
            color: Colors.green,
            tasks: completedTasks,
            onToggle: _toggleTaskCompletion,
            onEdit: _navigateToEditTask,
            onDelete: _deleteTask,
          ),
        if (_tasks.isEmpty)
          const Center(
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;

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

    return RefreshIndicator(onRefresh: _loadTasks, child: _buildTaskList());
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final Function(Task) onToggle;
  final Function(Task) onEdit;
  final Function(int) onDelete;

  const _TaskSection({
    required this.title,
    required this.color,
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...tasks.map(
            (task) => _TaskItem(
              task: task,
              onToggle: () => onToggle(task),
              onEdit: () => onEdit(task),
              onDelete: () => onDelete(task.id),
            ),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(vertical: 4),
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
            if (task.category != null) Text('Kategori: ${task.category!}'),
            if (task.priority != null) Text('Prioritas: ${task.priority!}'),
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
