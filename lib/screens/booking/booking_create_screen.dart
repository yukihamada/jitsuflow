import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../widgets/common/loading_widget.dart';

class BookingCreateScreen extends StatefulWidget {
  const BookingCreateScreen({super.key});

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedDojoId;
  String? _selectedClassType;
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _availableSlots = [];

  final List<Map<String, dynamic>> _dojos = [
    {'id': 1, 'name': 'Tokyo BJJ Dojo', 'address': '東京都渋谷区1-1-1'},
    {'id': 2, 'name': 'Osaka Grappling Academy', 'address': '大阪府大阪市北区2-2-2'},
    {'id': 3, 'name': 'Kyoto Traditional BJJ', 'address': '京都府京都市左京区3-3-3'},
  ];

  final List<String> _classTypes = [
    'ベーシック',
    'アドバンス',
    'コンペティション',
    'プライベート',
    'セミナー',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約作成'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('予約が正常に作成されました！'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BookingAvailabilitySuccess) {
            setState(() {
              _availableSlots = state.availableSlots;
            });
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dojo Selection
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '道場選択',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedDojoId,
                            decoration: const InputDecoration(
                              labelText: '道場を選択',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            items: _dojos.map((dojo) {
                              return DropdownMenuItem<int>(
                                value: dojo['id'],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dojo['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      dojo['address'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDojoId = value;
                                _selectedTime = null;
                                _availableSlots = [];
                              });
                              _loadAvailability();
                            },
                            validator: (value) {
                              if (value == null) {
                                return '道場を選択してください';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Class Type Selection
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'クラスタイプ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedClassType,
                            decoration: const InputDecoration(
                              labelText: 'クラスタイプを選択',
                              prefixIcon: Icon(Icons.sports_martial_arts),
                              border: OutlineInputBorder(),
                            ),
                            items: _classTypes.map((classType) {
                              return DropdownMenuItem<String>(
                                value: classType,
                                child: Text(classType),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClassType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'クラスタイプを選択してください';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Selection
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '日付選択',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedTime = null;
                                  _availableSlots = [];
                                });
                                _loadAvailability();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null
                                        ? '日付を選択'
                                        : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedDate == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Selection
                  if (_availableSlots.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '時間選択',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableSlots.map((slot) {
                                return ChoiceChip(
                                  label: Text(slot),
                                  selected: _selectedTime == slot,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedTime = selected ? slot : null;
                                    });
                                  },
                                  selectedColor: const Color(0xFF1B5E20),
                                  labelStyle: TextStyle(
                                    color: _selectedTime == slot
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  const Spacer(),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state is BookingLoading
                          ? null
                          : _canSubmit()
                              ? _submitBooking
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is BookingLoading
                          ? const LoadingWidget()
                          : const Text(
                              '予約を作成',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _canSubmit() {
    return _selectedDojoId != null &&
           _selectedClassType != null &&
           _selectedDate != null &&
           _selectedTime != null;
  }

  void _loadAvailability() {
    if (_selectedDojoId != null && _selectedDate != null) {
      context.read<BookingBloc>().add(
        BookingAvailabilityRequested(
          dojoId: _selectedDojoId!,
          date: _selectedDate!,
        ),
      );
    }
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate() && _canSubmit()) {
      context.read<BookingBloc>().add(
        BookingCreateRequested(
          dojoId: _selectedDojoId!,
          classType: _selectedClassType!,
          bookingDate: _selectedDate!,
          bookingTime: _selectedTime!,
        ),
      );
    }
  }
}