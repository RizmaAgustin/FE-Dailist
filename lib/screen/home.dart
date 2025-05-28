import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    HomeScreenContent(),
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
        isDark
            ? const Color(0xFF303030)
            : const Color(0xFFEDF7FE); // Warna biru muda

    return Scaffold(
      backgroundColor:
          backgroundColor, // Set warna latar belakang seluruh halaman
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

class HomeScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark
            ? const Color(0xFF303030)
            : const Color(0xFFEDF7FE); // Warna biru muda
    final cardColor = isDark ? Colors.grey[800]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Column(
      children: [
        AppBar(
          backgroundColor:
              backgroundColor, // Set warna AppBar menjadi biru muda
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.grey[900]
                            : Colors
                                .white, // Warna latar belakang TextField sesuai tema
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: textColor),
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: textColor,
                    ), // Warna teks input sesuai tema
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
          child: SingleChildScrollView(
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
                        5,
                        Icons.work,
                        cardColor,
                        textColor,
                      ),
                      _buildCategoryCard(
                        'Pribadi',
                        6,
                        Icons.person,
                        cardColor,
                        textColor,
                      ),
                      _buildCategoryCard(
                        'Belajar',
                        4,
                        Icons.book,
                        cardColor,
                        textColor,
                      ),
                      _buildCategoryCard(
                        'Semua',
                        13,
                        Icons.folder,
                        cardColor,
                        textColor,
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
                ClickableTaskItem(
                  title: 'Kerja Kelompok',
                  time: '10:00',
                  textColor: textColor,
                  secondaryTextColor: Colors.blue,
                ),
                ClickableTaskItem(
                  title: 'Olahraga',
                  time: '12:00',
                  textColor: textColor,
                  secondaryTextColor: Colors.blue,
                ),
                ClickableTaskItem(
                  title: 'Absensi Siakad',
                  time: '14:00',
                  textColor: textColor,
                  secondaryTextColor: Colors.blue,
                ),
                ClickableTaskItem(
                  title: 'Membersihkan Rumah',
                  time: '16:00',
                  textColor: textColor,
                  secondaryTextColor: Colors.blue,
                ),
                const SizedBox(height: 80.0),
              ],
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
                  );
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

  // ... (widget _buildCategoryCard dan ClickableTaskItem tetap sama)
  Widget _buildCategoryCard(
    String title,
    int count,
    IconData icon,
    Color cardColor,
    Color textColor,
  ) {
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: () {
          print('Kategori $title diklik!');
        },
        child: Card(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(icon, size: 30, color: textColor),
                const SizedBox(height: 8),
                Text(
                  '$count $title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClickableTaskItem extends StatefulWidget {
  final String title;
  final String time;
  final Color textColor;
  final Color secondaryTextColor;

  const ClickableTaskItem({
    super.key,
    required this.title,
    required this.time,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  State<ClickableTaskItem> createState() => _ClickableTaskItemState();
}

class _ClickableTaskItemState extends State<ClickableTaskItem> {
  bool _isClicked = false;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isClicked = !_isClicked;
        });
      },
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
                _isClicked
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _isClicked ? widget.secondaryTextColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(fontSize: 16, color: widget.textColor),
                ),
              ),
              Text(
                widget.time,
                style: TextStyle(
                  color: _isClicked ? widget.secondaryTextColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
