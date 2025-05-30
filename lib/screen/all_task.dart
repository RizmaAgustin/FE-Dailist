import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_task.dart';
import '../theme/theme_provider.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
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
          onPressed: () {
            Navigator.pop(context);
          },
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
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: const _AllTasksContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          // Refresh tasks after returning
          _AllTasksContentState? state =
              _AllTasksContent.globalKey.currentState;
          state?.fetchTasks();
        },
        backgroundColor: const Color(0xFF2196F3),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class Task {
  final int id; // assuming each task has an id for update
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      dueDate:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['is_completed'] == 1,
    );
  }
}

class _AllTasksContent extends StatefulWidget {
  const _AllTasksContent({Key? key}) : super(key: key);

  static final globalKey = GlobalKey<_AllTasksContentState>();

  @override
  State<_AllTasksContent> createState() => _AllTasksContentState();
}

class _AllTasksContentState extends State<_AllTasksContent> {
  List<Task> tasks = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final url = Uri.parse('http://127.0.0.1:8000/api/tasks');

    final token = await getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          tasks = data.map((json) => Task.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load tasks. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching tasks: $e';
        isLoading = false;
      });
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/api/tasks/${task.id}/toggle-completion',
    ); // contoh endpoint
    final token = await getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state dengan fetch ulang
        await fetchTasks();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal update status tugas.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saat update status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: fetchTasks,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final lateTasks =
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isBefore(now),
            )
            .toList();
    final priorityTasks =
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  (t.dueDate == null || !t.dueDate!.isBefore(now)),
            )
            .toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return SafeArea(
      child: ListView(
        children: [
          if (lateTasks.isNotEmpty)
            _TaskSection(
              title: 'Terlambat',
              color: Colors.orange,
              isDark: isDark,
              cardColor: cardColor,
              tasks:
                  lateTasks
                      .map(
                        (t) => TaskItem(
                          task: t,
                          onToggleCompleted: () => toggleTaskCompletion(t),
                        ),
                      )
                      .toList(),
            ),
          if (priorityTasks.isNotEmpty)
            _TaskSection(
              title: 'Tugas Prioritas',
              color: Colors.blue,
              isDark: isDark,
              cardColor: cardColor,
              tasks:
                  priorityTasks
                      .map(
                        (t) => TaskItem(
                          task: t,
                          onToggleCompleted: () => toggleTaskCompletion(t),
                        ),
                      )
                      .toList(),
            ),
          if (completedTasks.isNotEmpty)
            _TaskSection(
              title: 'Tugas Selesai',
              color: Colors.green,
              isDark: isDark,
              cardColor: cardColor,
              tasks:
                  completedTasks
                      .map(
                        (t) => TaskItem(
                          task: t,
                          onToggleCompleted: () => toggleTaskCompletion(t),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final Color color;
  final bool isDark;
  final Color cardColor;
  final List<TaskItem> tasks;

  const _TaskSection({
    required this.title,
    required this.color,
    required this.isDark,
    required this.cardColor,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
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
          ...tasks,
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleCompleted;

  const TaskItem({required this.task, required this.onToggleCompleted});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dueDateText =
        task.dueDate != null ? dateFormat.format(task.dueDate!) : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleCompleted(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('Deadline: $dueDateText'),
      ),
    );
  }
}
