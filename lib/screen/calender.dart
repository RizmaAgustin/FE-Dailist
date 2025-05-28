import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late List<List<int?>> _calendarDays;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _generateCalendarDays(_currentMonth);
  }

  void _generateCalendarDays(DateTime month) {
    _calendarDays = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysBefore = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;

    List<int?> week = [];
    for (int i = 0; i < daysBefore; i++) {
      week.add(null);
    }
    for (int i = 1; i <= totalDays; i++) {
      week.add(i);
      if (week.length == 7) {
        _calendarDays.add(week);
        week = [];
      }
    }
    if (week.isNotEmpty) {
      while (week.length < 7) {
        week.add(null);
      }
      _calendarDays.add(week);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _generateCalendarDays(_currentMonth);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _generateCalendarDays(_currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme == ThemeMode.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final backgroundColor =
        isDark ? const Color(0xFF303030) : const Color(0xFFEDF7FE);

    final today = DateTime.now();
    final isSameMonth =
        today.year == _currentMonth.year && today.month == _currentMonth.month;

    final formattedFullDate = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(today); // Menampilkan tanggal hari ini, bukan tanggal 1 bulan

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
        title: Text(
          'Kalender',
          style: TextStyle(
            color: iconColor,
            fontSize: 24,
            fontFamily: 'Signika',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: iconColor,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 348,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.85),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 15.5,
                offset: Offset(10, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 18.6,
                        color: Colors.grey,
                      ),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      formattedFullDate,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF828282),
                        fontSize: 15.5,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18.6,
                        color: Colors.grey,
                      ),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 12.4),
                const Divider(color: Color(0xFFBDBDBD), thickness: 0.77),
                const SizedBox(height: 12.4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text(
                      'Sun',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                    Text(
                      'Mon',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                    Text(
                      'Tue',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                    Text(
                      'Wed',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                    Text(
                      'Thu',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                    Text(
                      'Fri',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                    Text(
                      'Sat',
                      style: TextStyle(fontSize: 13, fontFamily: 'Lato'),
                    ),
                  ],
                ),
                const SizedBox(height: 12.4),
                ..._calendarDays.map(
                  (week) =>
                      _buildCalendarRow(week, isSameMonth ? today.day : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarRow(List<int?> days, int? today) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            days.map((day) {
              final isToday = day == today;
              return Container(
                width: 35.77,
                height: 35.77,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? const Color(0xFF2F80ED) : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    day?.toString() ?? '',
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
