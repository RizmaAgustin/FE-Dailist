import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/theme_provider.dart';
import 'add_task.dart';
import 'all_task.dart';
import 'calender.dart';
import 'setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreenContent(),
    const AllTasksScreen(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF303030) : const Color(0xFFEDF7FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Theme.of(context).hintColor,
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
}

class Task {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.priority,
    this.dueDate,
    this.createdAt,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      description: json['description'],
      category: json['category']?.toString().trim(),
      priority: json['priority'],
      dueDate:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }

  String get formattedTime {
    if (dueDate == null) return 'No time';
    return '${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    if (dueDate == null) return 'No date';
    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadTasks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final token = await _getToken();
      final email = await _getEmail();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/tasks?email=$email'),
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
          });
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat tugas: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> _getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> get _filteredTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      // Filter by category (case insensitive and handles null)
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          (task.category != null &&
              task.category!.toLowerCase() == _selectedCategory.toLowerCase());

      // Filter by search query
      final matchesSearch =
          _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by today's date
      final isToday =
          task.dueDate != null &&
          task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;

      return matchesCategory && matchesSearch && isToday;
    }).toList();
  }

  Widget _buildCategoryCard(
    String title,
    int count,
    IconData icon,
    Color cardColor,
    Color textColor, {
    bool isSelected = false,
  }) {
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = title;
          });
        },
        child: Card(
          color: isSelected ? Colors.blue.withOpacity(0.2) : cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                isSelected
                    ? BorderSide(color: Colors.blue, width: 2)
                    : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: isSelected ? Colors.blue : textColor,
                ),
                const SizedBox(height: 8),
                Text(
                  '$count $title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.blue : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF303030) : const Color(0xFFEDF7FE);
    final cardColor = isDark ? Colors.grey[800]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    final categoryCounts = {
      'Kerja':
          _tasks
              .where((task) => task.category?.toLowerCase() == 'kerja')
              .length,
      'Pribadi':
          _tasks
              .where((task) => task.category?.toLowerCase() == 'pribadi')
              .length,
      'Belajar':
          _tasks
              .where((task) => task.category?.toLowerCase() == 'belajar')
              .length,
      'Semua': _tasks.length,
    };

    return Column(
      children: [
        AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: textColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Cari Tugas',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  Provider.of<ThemeProvider>(context).currentTheme ==
                          ThemeMode.light
                      ? Icons.nightlight_round
                      : Icons.wb_sunny,
                  color: textColor,
                ),
                onPressed: () {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTasks,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: Wrap(
                              spacing: 16.0,
                              runSpacing: 16.0,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildCategoryCard(
                                  'Kerja',
                                  categoryCounts['Kerja']!,
                                  Icons.work,
                                  cardColor,
                                  textColor,
                                  isSelected: _selectedCategory == 'Kerja',
                                ),
                                _buildCategoryCard(
                                  'Pribadi',
                                  categoryCounts['Pribadi']!,
                                  Icons.person,
                                  cardColor,
                                  textColor,
                                  isSelected: _selectedCategory == 'Pribadi',
                                ),
                                _buildCategoryCard(
                                  'Belajar',
                                  categoryCounts['Belajar']!,
                                  Icons.book,
                                  cardColor,
                                  textColor,
                                  isSelected: _selectedCategory == 'Belajar',
                                ),
                                _buildCategoryCard(
                                  'Semua',
                                  categoryCounts['Semua']!,
                                  Icons.folder,
                                  cardColor,
                                  textColor,
                                  isSelected: _selectedCategory == 'Semua',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tugas Hari Ini',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          if (_filteredTasks.isEmpty)
                            Center(
                              child: Text(
                                'Tidak ada tugas untuk hari ini',
                                style: TextStyle(color: textColor),
                              ),
                            )
                          else
                            ..._filteredTasks.map(
                              (task) => TaskItem(
                                title: task.title,
                                time: task.formattedTime,
                                date: task.formattedDate,
                                textColor: textColor,
                                secondaryTextColor: Colors.blue,
                                isCompleted: task.isCompleted,
                                onTap: () => _toggleTaskCompletion(task),
                              ),
                            ),
                          const SizedBox(height: 80.0),
                        ],
                      ),
                    ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTaskScreen(),
                    ),
                  ).then((_) => _loadTasks());
                },
                backgroundColor: Colors.blue,
                heroTag: 'add',
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 16.0),
              FloatingActionButton(
                onPressed: () {
                  // TODO: aksi generate PDF
                },
                backgroundColor: Colors.blue,
                heroTag: 'pdf',
                shape: const CircleBorder(),
                child: const Icon(Icons.picture_as_pdf, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TaskItem extends StatelessWidget {
  final String title;
  final String time;
  final String date;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isCompleted;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.title,
    required this.time,
    required this.date,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isCompleted ? secondaryTextColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? secondaryTextColor : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
