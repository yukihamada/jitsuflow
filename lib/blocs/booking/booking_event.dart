part of 'booking_bloc.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class BookingLoadRequested extends BookingEvent {
  const BookingLoadRequested();
}

class BookingCreateRequested extends BookingEvent {
  final int dojoId;
  final String classType;
  final DateTime bookingDate;
  final String bookingTime;

  const BookingCreateRequested({
    required this.dojoId,
    required this.classType,
    required this.bookingDate,
    required this.bookingTime,
  });

  @override
  List<Object> get props => [dojoId, classType, bookingDate, bookingTime];
}

class BookingAvailabilityRequested extends BookingEvent {
  final int dojoId;
  final DateTime date;

  const BookingAvailabilityRequested({
    required this.dojoId,
    required this.date,
  });

  @override
  List<Object> get props => [dojoId, date];
}