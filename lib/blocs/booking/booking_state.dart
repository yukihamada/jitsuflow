part of 'booking_bloc.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoadSuccess extends BookingState {
  final List<Booking> bookings;

  const BookingLoadSuccess({required this.bookings});

  @override
  List<Object> get props => [bookings];
}

class BookingCreateSuccess extends BookingState {
  final Booking booking;

  const BookingCreateSuccess({required this.booking});

  @override
  List<Object> get props => [booking];
}

class BookingAvailabilitySuccess extends BookingState {
  final List<String> availableSlots;
  final DateTime date;
  final int dojoId;

  const BookingAvailabilitySuccess({
    required this.availableSlots,
    required this.date,
    required this.dojoId,
  });

  @override
  List<Object> get props => [availableSlots, date, dojoId];
}

class BookingFailure extends BookingState {
  final String message;

  const BookingFailure({required this.message});

  @override
  List<Object> get props => [message];
}