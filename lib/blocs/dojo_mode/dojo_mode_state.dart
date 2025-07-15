import '../../models/rental.dart';

abstract class DojoModeState {}

class DojoModeInitial extends DojoModeState {}

class DojoModeLoading extends DojoModeState {}

class DojoModeLoaded extends DojoModeState {
  final int dojoId;
  final bool isDojoMode;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> todaySales;
  final List<Rental> rentals;
  final List<Map<String, dynamic>> products;
  final bool isProcessingPayment;
  final Map<String, dynamic>? lastPaymentResult;
  final String? lastPaymentError;
  final bool isRecording;
  final int? currentRecordingId;
  final DateTime? recordingStartTime;
  final String? lastRecordingError;

  DojoModeLoaded({
    required this.dojoId,
    required this.isDojoMode,
    required this.settings,
    required this.todaySales,
    required this.rentals,
    required this.products,
    this.isProcessingPayment = false,
    this.lastPaymentResult,
    this.lastPaymentError,
    this.isRecording = false,
    this.currentRecordingId,
    this.recordingStartTime,
    this.lastRecordingError,
  });

  DojoModeLoaded copyWith({
    int? dojoId,
    bool? isDojoMode,
    Map<String, dynamic>? settings,
    List<Map<String, dynamic>>? todaySales,
    List<Rental>? rentals,
    List<Map<String, dynamic>>? products,
    bool? isProcessingPayment,
    Map<String, dynamic>? lastPaymentResult,
    String? lastPaymentError,
    bool? isRecording,
    int? currentRecordingId,
    DateTime? recordingStartTime,
    String? lastRecordingError,
  }) {
    return DojoModeLoaded(
      dojoId: dojoId ?? this.dojoId,
      isDojoMode: isDojoMode ?? this.isDojoMode,
      settings: settings ?? this.settings,
      todaySales: todaySales ?? this.todaySales,
      rentals: rentals ?? this.rentals,
      products: products ?? this.products,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      lastPaymentResult: lastPaymentResult ?? this.lastPaymentResult,
      lastPaymentError: lastPaymentError,
      isRecording: isRecording ?? this.isRecording,
      currentRecordingId: currentRecordingId ?? this.currentRecordingId,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      lastRecordingError: lastRecordingError,
    );
  }

  int get todayTotalSales {
    return todaySales.fold(0, (sum, sale) => sum + (sale['total_amount'] as int? ?? 0));
  }

  String get formattedTodayTotal {
    return '¥${todayTotalSales.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Duration? get currentRecordingDuration {
    if (recordingStartTime == null) return null;
    return DateTime.now().difference(recordingStartTime!);
  }
}

class DojoModeError extends DojoModeState {
  final String message;
  
  DojoModeError(this.message);
}