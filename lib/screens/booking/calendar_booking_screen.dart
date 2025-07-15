/**
 * カレンダー形式の予約画面
 * table_calendarを使用した直感的な予約管理
 */

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../themes/colorful_theme.dart';
import '../../models/class_info.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import 'class_detail_screen.dart';

class CalendarBookingScreen extends StatefulWidget {
  const CalendarBookingScreen({super.key});

  @override
  State<CalendarBookingScreen> createState() => _CalendarBookingScreenState();
}

class _CalendarBookingScreenState extends State<CalendarBookingScreen> {
  final _apiService = ApiService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<ClassInfo>> _classEvents = {};
  List<Booking> _userBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      setState(() => _isLoading = true);
      
      // クラススケジュール取得
      final classResponse = await _apiService.get('/api/classes/schedule');
      final bookingResponse = await _apiService.get('/api/bookings/user');
      
      final Map<DateTime, List<ClassInfo>> events = {};
      
      for (final classData in classResponse['classes']) {
        final classInfo = ClassInfo.fromJson(classData);
        final date = DateTime(
          classInfo.startTime.year,
          classInfo.startTime.month,
          classInfo.startTime.day,
        );
        
        if (events[date] == null) {
          events[date] = [];
        }
        events[date]!.add(classInfo);
      }
      
      setState(() {
        _classEvents = events;
        _userBookings = (bookingResponse['bookings'] as List)
            .map((b) => Booking.fromJson(b))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データの取得に失敗しました: $e')),
      );
    }
  }

  List<ClassInfo> _getClassesForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _classEvents[normalizedDay] ?? [];
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    return _userBookings.where((booking) {
      final bookingDate = DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
      );
      final selectedDate = DateTime(day.year, day.month, day.day);
      return bookingDate.isAtSameMomentAs(selectedDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColorfulTheme.gradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // カスタムAppBar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'クラス予約カレンダー',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.today, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDay = DateTime.now();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // カレンダーとクラス一覧
              Expanded(
                child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // カレンダー
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: TableCalendar<ClassInfo>(
                              firstDay: DateTime.utc(2024, 1, 1),
                              lastDay: DateTime.utc(2025, 12, 31),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              eventLoader: _getClassesForDay,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              
                              // カレンダースタイル
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                selectedDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: ColorfulTheme.primaryGradient,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: ColorfulTheme.accentAmber,
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: BoxDecoration(
                                  color: ColorfulTheme.accentLime,
                                  shape: BoxShape.circle,
                                ),
                                weekendTextStyle: TextStyle(
                                  color: ColorfulTheme.secondaryGradient[1],
                                ),
                              ),
                              
                              // ヘッダースタイル
                              headerStyle: HeaderStyle(
                                formatButtonVisible: true,
                                titleCentered: true,
                                formatButtonShowsNext: false,
                                formatButtonDecoration: BoxDecoration(
                                  color: ColorfulTheme.accentCyan,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                formatButtonTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  color: ColorfulTheme.primaryGradient[1],
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  color: ColorfulTheme.primaryGradient[1],
                                ),
                              ),
                              
                              selectedDayPredicate: (day) {
                                return isSameDay(_selectedDay, day);
                              },
                              
                              onDaySelected: (selectedDay, focusedDay) {
                                if (!isSameDay(_selectedDay, selectedDay)) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                }
                              },
                              
                              onFormatChanged: (format) {
                                if (_calendarFormat != format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                }
                              },
                              
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                            ),
                          ),
                          
                          const Divider(height: 1),
                          
                          // 選択日のクラス一覧
                          Expanded(
                            child: _buildClassList(),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('日付を選択してください'),
      );
    }

    final selectedClasses = _getClassesForDay(_selectedDay!);
    final userBookings = _getBookingsForDay(_selectedDay!);
    final dateFormat = DateFormat('M月d日(E)', 'ja_JP');

    if (selectedClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '${dateFormat.format(_selectedDay!)}は\nクラスがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.event,
                color: ColorfulTheme.primaryGradient[1],
              ),
              const SizedBox(width: 8),
              Text(
                '${dateFormat.format(_selectedDay!)} のクラス',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorfulTheme.accentLime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedClasses.length}クラス',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColorfulTheme.accentLime,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: selectedClasses.length,
            itemBuilder: (context, index) {
              final classInfo = selectedClasses[index];
              final isBooked = userBookings.any((b) => b.classType == classInfo.classType);
              
              return _buildClassCard(classInfo, isBooked, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(ClassInfo classInfo, bool isBooked, int index) {
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorfulTheme.getChipColor(index).withOpacity(0.1),
            ColorfulTheme.getChipColor(index).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorfulTheme.getChipColor(index).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDetailScreen(classInfo: classInfo),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 時間
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorfulTheme.getChipColor(index),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${timeFormat.format(classInfo.startTime)} - ${timeFormat.format(classInfo.endTime)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 予約状態
                    if (isBooked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '予約済み',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // クラス名とタイプ
                Text(
                  classInfo.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  classInfo.classTypeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // インストラクターと定員
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      classInfo.instructorName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${classInfo.currentStudents}/${classInfo.maxStudents}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 技術タグ
                if (classInfo.techniques.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: classInfo.techniques.take(3).map((technique) => 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorfulTheme.getChipColor(index).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          technique,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorfulTheme.getChipColor(index),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}