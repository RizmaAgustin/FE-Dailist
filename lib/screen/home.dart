import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../theme/theme_provider.dart';
import 'add_task.dart';
import 'all_task.dart';
import 'calender.dart';
import 'setting.dart';
import '../services/notification_service.dart';
import '../services/api_services.dart';

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
    return DateFormat('HH:mm').format(dueDate!);
  }

  String get formattedDate {
    if (dueDate == null) return 'No date';
    return DateFormat('dd/MM/yyyy').format(dueDate!);
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token login tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }
      final result = await ApiService.fetchTasks(token: token);
      if (result['status'] == 200) {
        final List<dynamic> data = result['body'];
        List<Task> loadedTasks =
            data.map((json) => Task.fromJson(json)).toList();

        setState(() {
          _tasks = loadedTasks;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load tasks: ${result['status']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tasks: ${e.toString()}';
        _isLoading = false;
      });
    }
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
                createdAt: t.createdAt,
                isCompleted: !t.isCompleted,
              );
            }
            return t;
          }).toList();
    });

    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token login tidak ditemukan.')),
        );
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
                    createdAt: t.createdAt,
                    isCompleted: wasCompleted,
                  );
                }
                return t;
              }).toList();
        });
        return;
      }
      final result = await ApiService.toggleTaskCompletion(
        token: token,
        taskId: task.id,
        isCompleted: !task.isCompleted,
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
      await _loadTasks();
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
                  createdAt: t.createdAt,
                  isCompleted: wasCompleted,
                );
              }
              return t;
            }).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change status: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (pw.Context context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Task List Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headers: [
                  '#',
                  'Title',
                  'Category',
                  'Priority',
                  'Due Date',
                  'Status',
                ],
                data:
                    _tasks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final task = entry.value;
                      return [
                        (i + 1).toString(),
                        task.title,
                        task.category ?? '-',
                        task.priority ?? '-',
                        task.dueDate != null
                            ? DateFormat('yyyy-MM-dd').format(task.dueDate!)
                            : '-',
                        task.isCompleted ? 'Completed' : 'Pending',
                      ];
                    }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Tasks: ${_tasks.length}'),
              pw.Text(
                'Completed: ${_tasks.where((t) => t.isCompleted).length}',
              ),
              pw.Text('Pending: ${_tasks.where((t) => !t.isCompleted).length}'),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> get _filteredTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          (task.category != null &&
              task.category!.toLowerCase() == _selectedCategory.toLowerCase());

      final matchesSearch =
          _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());

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
      width: 140,
      height: 140,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = title;
          });
        },
        child: Card(
          color:
              isSelected ? Colors.blue.withValues(alpha: 0.2 * 255) : cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                isSelected
                    ? const BorderSide(color: Colors.blue, width: 2)
                    : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  textAlign: TextAlign.center,
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
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.blue;

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
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTasks,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: Text(
                              'Kategori',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double gridMaxWidth =
                                    constraints.maxWidth > 320
                                        ? 320
                                        : constraints.maxWidth;
                                return Center(
                                  child: SizedBox(
                                    width: gridMaxWidth,
                                    child: GridView.count(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                        _buildCategoryCard(
                                          'Kerja',
                                          categoryCounts['Kerja']!,
                                          Icons.work,
                                          cardColor,
                                          textColor,
                                          isSelected:
                                              _selectedCategory == 'Kerja',
                                        ),
                                        _buildCategoryCard(
                                          'Pribadi',
                                          categoryCounts['Pribadi']!,
                                          Icons.person,
                                          cardColor,
                                          textColor,
                                          isSelected:
                                              _selectedCategory == 'Pribadi',
                                        ),
                                        _buildCategoryCard(
                                          'Belajar',
                                          categoryCounts['Belajar']!,
                                          Icons.book,
                                          cardColor,
                                          textColor,
                                          isSelected:
                                              _selectedCategory == 'Belajar',
                                        ),
                                        _buildCategoryCard(
                                          'Semua',
                                          categoryCounts['Semua']!,
                                          Icons.folder,
                                          cardColor,
                                          textColor,
                                          isSelected:
                                              _selectedCategory == 'Semua',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tugas Hari Ini",
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
                                'Tidak ada tugas hari ini.',
                                style: TextStyle(color: textColor),
                              ),
                            )
                          else
                            ..._filteredTasks.map(
                              (task) => TaskItem(
                                title: task.title,
                                time: task.formattedTime,
                                date: task.formattedDate,
                                dueDate: task.dueDate,
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
                onPressed: _generatePdf,
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
  final DateTime? dueDate;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isCompleted;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.title,
    required this.time,
    required this.date,
    required this.dueDate,
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

    final bool isDeadlinePassed =
        dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

    final Color titleColor = isDeadlinePassed ? Colors.red : textColor;
    final Color dateColor = isDeadlinePassed ? Colors.red : secondaryTextColor;
    final Color timeColor =
        isDeadlinePassed
            ? Colors.red
            : (isCompleted ? secondaryTextColor : Colors.blue);

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
                        color: titleColor,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: dateColor),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: timeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
