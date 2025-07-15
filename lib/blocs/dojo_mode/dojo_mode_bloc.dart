import 'package:flutter_bloc/flutter_bloc.dart';
import 'dojo_mode_event.dart';
import 'dojo_mode_state.dart';
import '../../services/api_service.dart';

class DojoModeBloc extends Bloc<DojoModeEvent, DojoModeState> {
  DojoModeBloc() : super(DojoModeInitial()) {
    on<LoadDojoModeData>(_onLoadDojoModeData);
    on<SwitchToDojoMode>(_onSwitchToDojoMode);
    on<SwitchToUserMode>(_onSwitchToUserMode);
    on<ProcessPayment>(_onProcessPayment);
    on<AddRentalTransaction>(_onAddRentalTransaction);
    on<StartSparringRecording>(_onStartSparringRecording);
    on<StopSparringRecording>(_onStopSparringRecording);
  }

  Future<void> _onLoadDojoModeData(
    LoadDojoModeData event,
    Emitter<DojoModeState> emit,
  ) async {
    emit(DojoModeLoading());
    
    try {
      // Load dojo mode data including settings, current sales, etc.
      final data = await ApiService.getDojoModeData(event.dojoId);
      emit(DojoModeLoaded(
        dojoId: event.dojoId,
        isDojoMode: false,
        settings: data['settings'],
        todaySales: data['today_sales'] ?? [],
        rentals: data['rentals'] ?? [],
        products: data['products'] ?? [],
      ));
    } catch (error) {
      emit(DojoModeError(error.toString()));
    }
  }

  Future<void> _onSwitchToDojoMode(
    SwitchToDojoMode event,
    Emitter<DojoModeState> emit,
  ) async {
    if (state is DojoModeLoaded) {
      final currentState = state as DojoModeLoaded;
      emit(currentState.copyWith(isDojoMode: true));
    }
  }

  Future<void> _onSwitchToUserMode(
    SwitchToUserMode event,
    Emitter<DojoModeState> emit,
  ) async {
    if (state is DojoModeLoaded) {
      final currentState = state as DojoModeLoaded;
      emit(currentState.copyWith(isDojoMode: false));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<DojoModeState> emit,
  ) async {
    if (state is DojoModeLoaded) {
      final currentState = state as DojoModeLoaded;
      emit(currentState.copyWith(isProcessingPayment: true));
      
      try {
        final result = await ApiService.processDojoPayment(
          event.dojoId,
          event.items,
          event.paymentMethod,
          event.customerId,
        );
        
        // Reload today's sales
        final updatedSales = await ApiService.getTodaySales(event.dojoId);
        
        emit(currentState.copyWith(
          isProcessingPayment: false,
          todaySales: updatedSales,
          lastPaymentResult: result,
        ));
      } catch (error) {
        emit(currentState.copyWith(
          isProcessingPayment: false,
          lastPaymentError: error.toString(),
        ));
      }
    }
  }

  Future<void> _onAddRentalTransaction(
    AddRentalTransaction event,
    Emitter<DojoModeState> emit,
  ) async {
    if (state is DojoModeLoaded) {
      final currentState = state as DojoModeLoaded;
      
      try {
        await ApiService.addRentalTransaction(
          event.rentalId,
          event.userId,
          event.returnDueDate,
        );
        
        // Reload rentals to update availability
        final updatedRentals = await ApiService.getRentals(event.dojoId);
        
        emit(currentState.copyWith(rentals: updatedRentals));
      } catch (error) {
        emit(DojoModeError(error.toString()));
      }
    }
  }

  Future<void> _onStartSparringRecording(
    StartSparringRecording event,
    Emitter<DojoModeState> emit,
  ) async {
    if (state is DojoModeLoaded) {
      final currentState = state as DojoModeLoaded;
      emit(currentState.copyWith(isRecording: true));
      
      try {
        final recordingId = await ApiService.startSparringRecording(
          event.dojoId,
          event.participant1Id,
          event.participant2Id,
          event.ruleSet,
        );
        
        emit(currentState.copyWith(
          currentRecordingId: recordingId,
          recordingStartTime: DateTime.now(),
        ));
      } catch (error) {
        emit(currentState.copyWith(
          isRecording: false,
          lastRecordingError: error.toString(),
        ));
      }
    }
  }

  Future<void> _onStopSparringRecording(
    StopSparringRecording event,
    Emitter<DojoModeState> emit,
  ) async {
    if (state is DojoModeLoaded) {
      final currentState = state as DojoModeLoaded;
      
      try {
        await ApiService.stopSparringRecording(
          currentState.currentRecordingId!,
          event.winnerId,
          event.finishType,
        );
        
        emit(currentState.copyWith(
          isRecording: false,
          currentRecordingId: null,
          recordingStartTime: null,
        ));
      } catch (error) {
        emit(currentState.copyWith(
          lastRecordingError: error.toString(),
        ));
      }
    }
  }
}