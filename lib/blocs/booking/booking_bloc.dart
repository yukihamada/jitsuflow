import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(BookingInitial()) {
    on<BookingLoadRequested>(_onLoadRequested);
    on<BookingCreateRequested>(_onCreateRequested);
    on<BookingAvailabilityRequested>(_onAvailabilityRequested);
  }

  Future<void> _onLoadRequested(
    BookingLoadRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    
    try {
      final bookings = await ApiService.getBookings();
      emit(BookingLoadSuccess(bookings: bookings));
    } catch (e) {
      emit(BookingFailure(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    BookingCreateRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    
    try {
      final booking = await ApiService.createBooking(
        dojoId: event.dojoId,
        classType: event.classType,
        bookingDate: event.bookingDate,
        bookingTime: event.bookingTime,
      );
      
      emit(BookingCreateSuccess(booking: booking));
    } catch (e) {
      emit(BookingFailure(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityRequested(
    BookingAvailabilityRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    
    try {
      final availability = await ApiService.getAvailability(
        dojoId: event.dojoId,
        date: event.date,
      );
      
      emit(BookingAvailabilitySuccess(
        availableSlots: List<String>.from(availability['available_slots']),
        date: event.date,
        dojoId: event.dojoId,
      ));
    } catch (e) {
      emit(BookingFailure(message: e.toString()));
    }
  }
}