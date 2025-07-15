import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../themes/colorful_theme.dart';

class ScreenshotBookingScreen extends StatelessWidget {
  const ScreenshotBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDay = DateTime(today.year, today.month, 15);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'クラス予約',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // カレンダー
          Container(
            color: Colors.grey[900],
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.white70),
                defaultTextStyle: const TextStyle(color: Colors.white),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white70),
                weekendStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // クラス一覧
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildClassCard(
                  time: '10:00 - 11:30',
                  title: '朝のベーシッククラス',
                  instructor: '村田良蔵',
                  level: '初級〜中級',
                  availability: '空きあり（12/20名）',
                  isAvailable: true,
                ),
                _buildClassCard(
                  time: '13:00 - 14:30',
                  title: 'ノーギクラス',
                  instructor: '廣鰭翔大',
                  level: '全レベル',
                  availability: '残りわずか（18/20名）',
                  isAvailable: true,
                ),
                _buildClassCard(
                  time: '19:00 - 20:30',
                  title: 'アドバンスクラス',
                  instructor: '諸澤陽斗',
                  level: '中級〜上級',
                  availability: '満員',
                  isAvailable: false,
                ),
                _buildClassCard(
                  time: '20:30 - 22:00',
                  title: 'コンペティションクラス',
                  instructor: '松本志',
                  level: '上級',
                  availability: '空きあり（8/15名）',
                  isAvailable: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '予約',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: '動画',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'ショップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'アカウント',
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String time,
    required String title,
    required String instructor,
    required String level,
    required String availability,
    required bool isAvailable,
  }) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    availability,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  instructor,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.signal_cellular_alt, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  level,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('予約する'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}