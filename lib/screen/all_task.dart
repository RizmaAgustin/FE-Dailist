import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_task.dart';
import '../theme/theme_provider.dart'; // Pastikan path provider benar

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
        isDark
            ? const Color(0xFF303030)
            : const Color(0xFFEDF7FE); // Warna biru muda dari HomePage

    return Scaffold(
      backgroundColor: backgroundColor, // Set warna latar belakang di Scaffold
      appBar: AppBar(
        backgroundColor:
            backgroundColor, // Samakan warna AppBar dengan background
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
      body: _AllTasksContent(), // Langsung tampilkan konten
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        backgroundColor: const Color(0xFF2196F3),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AllTasksContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SafeArea(
      child: ListView(
        children: [
          _TaskSection(
            title: 'Terlambat',
            color: Colors.orange,
            isDark: isDark,
            cardColor: cardColor,
            tasks: [
              TaskItem(
                title: 'Pengumpulan Draft',
                dueDate: DateTime(2025, 4, 7),
                trailingIcon: Icons.edit_outlined,
              ),
            ],
          ),
          _TaskSection(
            title: 'Tugas Prioritas',
            color: Colors.blue,
            isDark: isDark,
            cardColor: cardColor,
            tasks: [
              TaskItem(
                title: 'Project Akhir Mobile',
                dueDate: DateTime(2025, 4, 22),
                trailingIcon: Icons.edit_outlined,
              ),
              TaskItem(
                title: 'Project UTS',
                dueDate: DateTime(2025, 4, 22),
                trailingIcon: Icons.edit_outlined,
              ),
            ],
          ),
          _TaskSection(
            title: 'Tugas Lainnya',
            color: Colors.grey,
            isDark: isDark,
            cardColor: cardColor,
            tasks: [
              TaskItem(
                title: 'Liburan Semester',
                dueDate: DateTime(2025, 4, 22),
                trailingIcon: Icons.edit_outlined,
              ),
              TaskItem(
                title: 'Kasih Makan Kucing',
                dueDate: DateTime(2025, 4, 22),
                trailingIcon: Icons.edit_outlined,
              ),
            ],
          ),
          _TaskSection(
            title: 'Tugas Selesai',
            color: Colors.green,
            isDark: isDark,
            cardColor: cardColor,
            tasks: [
              TaskItem(
                title: 'Tugas Artikel',
                dueDate: DateTime(2025, 4, 22),
                trailingIcon: Icons.delete_outline,
                isCompleted: true,
              ),
              TaskItem(
                title: 'Artikel Metode Penelitian',
                dueDate: DateTime(2025, 4, 22),
                trailingIcon: Icons.delete_outline,
                isCompleted: true,
              ),
            ],
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
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          ...tasks.map((task) => task.buildCard(cardColor, isDark)).toList(),
        ],
      ),
    );
  }
}

class TaskItem {
  final String title;
  final DateTime? dueDate;
  final IconData? trailingIcon;
  final bool isCompleted;

  const TaskItem({
    required this.title,
    this.dueDate,
    this.trailingIcon,
    this.isCompleted = false,
  });

  Widget buildCard(Color cardColor, bool isDark) {
    final formattedDate =
        dueDate != null
            ? DateFormat('EEEE, d MMMM y', 'id_ID').format(dueDate!)
            : '';
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle:
            dueDate != null
                ? Text(
                  formattedDate,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                )
                : null,
        trailing: Icon(
          trailingIcon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}
